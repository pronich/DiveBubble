package server

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/expense"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

func registerExpenseRoutes(mux *http.ServeMux, svc *expense.Service, tripSvc *trip.Service, authIssuer *auth.TokenIssuer) {
	mux.HandleFunc("GET /trips/{id}/expenses", withAuth(authIssuer, handleListExpenses(svc, tripSvc)))
	mux.HandleFunc("POST /trips/{id}/expenses", withAuth(authIssuer, handleCreateExpense(svc, tripSvc)))
	mux.HandleFunc("GET /trips/{id}/expenses/balance", withAuth(authIssuer, handleGetExpenseBalance(svc, tripSvc)))
	mux.HandleFunc("POST /trips/{id}/expenses/settlements", withAuth(authIssuer, handleCreateSettlement(svc, tripSvc)))
	mux.HandleFunc("GET /trips/{id}/expenses/{expenseId}", withAuth(authIssuer, handleGetExpense(svc, tripSvc)))
	mux.HandleFunc("PUT /trips/{id}/expenses/{expenseId}", withAuth(authIssuer, handleUpdateExpense(svc, tripSvc)))
	mux.HandleFunc("DELETE /trips/{id}/expenses/{expenseId}", withAuth(authIssuer, handleDeleteExpense(svc, tripSvc)))
}

// requireExpenseInTrip is requireParticipant (trip-level) plus an expense-level check —
// unlike transport's requireOfferAccess, there's no further per-expense membership subset:
// any trip participant may read/edit any expense, only Delete is more restrictive (enforced
// in expense.Service.Delete itself, since it needs CreatedBy which this already has in hand).
func requireExpenseInTrip(w http.ResponseWriter, r *http.Request, svc *expense.Service, tripID uuid.UUID, expenseIDStr string) (expense.Expense, bool) {
	expenseID, err := uuid.Parse(expenseIDStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid expense id")
		return expense.Expense{}, false
	}
	e, err := svc.GetByID(r.Context(), expenseID)
	if err != nil {
		if errors.Is(err, expense.ErrNotFound) {
			writeError(w, http.StatusNotFound, "expense not found")
			return expense.Expense{}, false
		}
		writeError(w, http.StatusInternalServerError, "could not load expense")
		return expense.Expense{}, false
	}
	if e.TripID != tripID {
		writeError(w, http.StatusNotFound, "expense not found")
		return expense.Expense{}, false
	}
	return e, true
}

type expenseShareRequest struct {
	UserID      uuid.UUID `json:"userId"`
	Shares      *int      `json:"shares,omitempty"`
	AmountMinor *int64    `json:"amountMinor,omitempty"`
}

// toSplitInput interprets the request's shares list according to splitType — equal only
// needs the participant ids, shares needs each one's share count, exact needs each one's
// exact amount. A missing field for the chosen mode is a client bug, reported as 400.
func toSplitInput(splitType expense.SplitType, reqShares []expenseShareRequest) (expense.SplitInput, error) {
	switch splitType {
	case expense.SplitEqual:
		ids := make([]uuid.UUID, len(reqShares))
		for i, s := range reqShares {
			ids[i] = s.UserID
		}
		return expense.SplitInput{ParticipantUserIDs: ids}, nil
	case expense.SplitShares:
		m := make(map[uuid.UUID]int, len(reqShares))
		for _, s := range reqShares {
			if s.Shares == nil {
				return expense.SplitInput{}, errors.New("every participant needs a shares count")
			}
			m[s.UserID] = *s.Shares
		}
		return expense.SplitInput{Shares: m}, nil
	case expense.SplitExact:
		m := make(map[uuid.UUID]int64, len(reqShares))
		for _, s := range reqShares {
			if s.AmountMinor == nil {
				return expense.SplitInput{}, errors.New("every participant needs an exact amount")
			}
			m[s.UserID] = *s.AmountMinor
		}
		return expense.SplitInput{ExactAmountsMinor: m}, nil
	default:
		return expense.SplitInput{}, errors.New("invalid split type")
	}
}

type expenseShareResponse struct {
	UserID      uuid.UUID `json:"userId"`
	Shares      *int      `json:"shares,omitempty"`
	AmountMinor int64     `json:"amountMinor"`
}

type expenseResponse struct {
	ID          uuid.UUID              `json:"id"`
	TripID      uuid.UUID              `json:"tripId"`
	PayerUserID uuid.UUID              `json:"payerUserId"`
	CreatedBy   uuid.UUID              `json:"createdBy"`
	Title       string                 `json:"title"`
	AmountMinor int64                  `json:"amountMinor"`
	SplitType   string                 `json:"splitType"`
	CreatedAt   time.Time              `json:"createdAt"`
	UpdatedAt   time.Time              `json:"updatedAt"`
	Shares      []expenseShareResponse `json:"shares"`
}

func toExpenseResponse(e expense.Expense) expenseResponse {
	shares := make([]expenseShareResponse, len(e.Shares))
	for i, s := range e.Shares {
		shares[i] = expenseShareResponse{UserID: s.UserID, Shares: s.Shares, AmountMinor: s.AmountMinor}
	}
	return expenseResponse{
		ID: e.ID, TripID: e.TripID, PayerUserID: e.PayerUserID, CreatedBy: e.CreatedBy,
		Title: e.Title, AmountMinor: e.AmountMinor, SplitType: string(e.SplitType),
		CreatedAt: e.CreatedAt, UpdatedAt: e.UpdatedAt, Shares: shares,
	}
}

func handleListExpenses(svc *expense.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		expenses, err := svc.ListByTrip(r.Context(), tripID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not list expenses")
			return
		}
		out := make([]expenseResponse, len(expenses))
		for i, e := range expenses {
			out[i] = toExpenseResponse(e)
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type createExpenseRequest struct {
	PayerUserID uuid.UUID             `json:"payerUserId"`
	Title       string                `json:"title"`
	AmountMinor int64                 `json:"amountMinor"`
	SplitType   string                `json:"splitType"`
	Shares      []expenseShareRequest `json:"shares"`
}

func handleCreateExpense(svc *expense.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		if err := tripSvc.EnsureNotCancelled(r.Context(), tripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, "trip has been cancelled")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not create expense")
			return
		}

		var req createExpenseRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		splitType := expense.SplitType(req.SplitType)
		input, err := toSplitInput(splitType, req.Shares)
		if err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}

		e, err := svc.Create(r.Context(), tripID, req.PayerUserID, userID, req.Title, req.AmountMinor, splitType, input)
		if err != nil {
			if errors.Is(err, expense.ErrSplitMismatch) {
				writeError(w, http.StatusBadRequest, "split amounts do not add up to the total")
				return
			}
			if errors.Is(err, expense.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid expense")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not create expense")
			return
		}
		writeJSON(w, http.StatusCreated, toExpenseResponse(e))
	}
}

func handleGetExpense(svc *expense.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		e, ok := requireExpenseInTrip(w, r, svc, tripID, r.PathValue("expenseId"))
		if !ok {
			return
		}
		writeJSON(w, http.StatusOK, toExpenseResponse(e))
	}
}

func handleUpdateExpense(svc *expense.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		if err := tripSvc.EnsureNotCancelled(r.Context(), tripID); err != nil {
			if errors.Is(err, trip.ErrTripCancelled) {
				writeError(w, http.StatusConflict, "trip has been cancelled")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not update expense")
			return
		}
		e, ok := requireExpenseInTrip(w, r, svc, tripID, r.PathValue("expenseId"))
		if !ok {
			return
		}

		var req createExpenseRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		splitType := expense.SplitType(req.SplitType)
		input, err := toSplitInput(splitType, req.Shares)
		if err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}

		updated, err := svc.Update(r.Context(), e.ID, req.PayerUserID, req.Title, req.AmountMinor, splitType, input)
		if err != nil {
			if errors.Is(err, expense.ErrSplitMismatch) {
				writeError(w, http.StatusBadRequest, "split amounts do not add up to the total")
				return
			}
			if errors.Is(err, expense.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid expense")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not update expense")
			return
		}
		writeJSON(w, http.StatusOK, toExpenseResponse(updated))
	}
}

// handleDeleteExpense is creator-only (expense.Service.Delete enforces it) — anyone else
// gets 403, matching transport's Dissolve pattern.
func handleDeleteExpense(svc *expense.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		e, ok := requireExpenseInTrip(w, r, svc, tripID, r.PathValue("expenseId"))
		if !ok {
			return
		}
		if err := svc.Delete(r.Context(), e.ID, userID); err != nil {
			if errors.Is(err, expense.ErrForbidden) {
				writeError(w, http.StatusForbidden, "only the creator can delete this expense")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not delete expense")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

type balanceResponse struct {
	UserID      uuid.UUID `json:"userId"`
	AmountMinor int64     `json:"amountMinor"`
}

type settlementResponse struct {
	FromUserID  uuid.UUID `json:"fromUserId"`
	ToUserID    uuid.UUID `json:"toUserId"`
	AmountMinor int64     `json:"amountMinor"`
}

type getBalanceResponse struct {
	Balances    []balanceResponse    `json:"balances"`
	Settlements []settlementResponse `json:"settlements"`
}

func handleGetExpenseBalance(svc *expense.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}
		balances, settlements, err := svc.GetBalance(r.Context(), tripID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "could not compute balance")
			return
		}
		balanceOut := make([]balanceResponse, len(balances))
		for i, b := range balances {
			balanceOut[i] = balanceResponse{UserID: b.UserID, AmountMinor: b.AmountMinor}
		}
		settlementOut := make([]settlementResponse, len(settlements))
		for i, s := range settlements {
			settlementOut[i] = settlementResponse{FromUserID: s.FromUserID, ToUserID: s.ToUserID, AmountMinor: s.AmountMinor}
		}
		writeJSON(w, http.StatusOK, getBalanceResponse{Balances: balanceOut, Settlements: settlementOut})
	}
}

type createSettlementRequest struct {
	FromUserID  uuid.UUID `json:"fromUserId"`
	ToUserID    uuid.UUID `json:"toUserId"`
	AmountMinor int64     `json:"amountMinor"`
}

// handleCreateSettlement records a payment in either direction relative to the caller — any
// participant can mark a suggested transfer settled, not just the one paying it off, per the
// product decision that this feature has no stricter permission model than editing an expense.
func handleCreateSettlement(svc *expense.Service, tripSvc *trip.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		tripID, ok := requireParticipant(w, r, tripSvc, r.PathValue("id"), userID)
		if !ok {
			return
		}

		var req createSettlementRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		s, err := svc.CreateSettlement(r.Context(), tripID, req.FromUserID, req.ToUserID, req.AmountMinor)
		if err != nil {
			if errors.Is(err, expense.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "invalid settlement")
				return
			}
			writeError(w, http.StatusInternalServerError, "could not record settlement")
			return
		}
		writeJSON(w, http.StatusCreated, settlementResponse{FromUserID: s.FromUserID, ToUserID: s.ToUserID, AmountMinor: s.AmountMinor})
	}
}
