package buddy

import (
	"context"
	"errors"

	"github.com/google/uuid"
)

var ErrFull = errors.New("buddy group is full")
var ErrAlreadyBooked = errors.New("already in a buddy group on this trip")
var ErrForbidden = errors.New("only the creator can do that")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

// Create takes no fields to validate — a buddy request is just "I want a buddy for this
// trip", nothing else to fill in.
func (s *Service) Create(ctx context.Context, tripID, userID uuid.UUID) (Request, error) {
	return s.Repo.Create(ctx, CreateParams{TripID: tripID, UserID: userID})
}

func (s *Service) List(ctx context.Context, tripID, callerUserID uuid.UUID) ([]Request, error) {
	return s.Repo.ListByTrip(ctx, tripID, callerUserID)
}

// Join returns the request joined — callers use it (specifically its UserID, the request's
// creator) to notify them that someone joined, without a second fetch.
func (s *Service) Join(ctx context.Context, requestID, userID uuid.UUID) (Request, error) {
	req, err := s.Repo.GetByID(ctx, requestID)
	if err != nil {
		return Request{}, err
	}

	alreadyJoined, err := s.Repo.IsJoined(ctx, requestID, userID)
	if err != nil {
		return Request{}, err
	}
	if alreadyJoined {
		return req, nil
	}

	// One buddy group per trip — a diver only needs one, regardless of how many requests exist.
	hasOtherBooking, err := s.Repo.HasAnyJoinInTrip(ctx, req.TripID, userID)
	if err != nil {
		return Request{}, err
	}
	if hasOtherBooking {
		return Request{}, ErrAlreadyBooked
	}

	count, err := s.Repo.CountJoins(ctx, requestID)
	if err != nil {
		return Request{}, err
	}
	// +1 for the creator — MaxMembers is the whole group's size, unlike transport's seats
	// (which only ever counted passengers, never the driver).
	if 1+count >= MaxMembers {
		return Request{}, ErrFull
	}
	if err := s.Repo.Join(ctx, requestID, userID); err != nil {
		return Request{}, err
	}
	return req, nil
}

func (s *Service) ListJoins(ctx context.Context, requestID uuid.UUID) ([]uuid.UUID, error) {
	return s.Repo.ListJoins(ctx, requestID)
}

// Leave lets a joined diver step out of a single buddy group — the request itself (and its
// chat) carries on for whoever's left. Deleting a non-existent join is a harmless no-op.
func (s *Service) Leave(ctx context.Context, requestID, userID uuid.UUID) error {
	return s.Repo.Leave(ctx, requestID, userID)
}

// Dissolve is the creator cancelling their own buddy request outright — deletes the request,
// cascading its joins and chat history. Only the creator may dissolve; anyone else gets
// ErrForbidden.
func (s *Service) Dissolve(ctx context.Context, requestID, userID uuid.UUID) error {
	req, err := s.Repo.GetByID(ctx, requestID)
	if err != nil {
		return err
	}
	if req.UserID != userID {
		return ErrForbidden
	}
	return s.Repo.DeleteRequest(ctx, requestID)
}

// HandleUserLeavingTrip mirrors transport's — drops this user's joins (frees the spot they
// held), and dissolves any request *they* created on this trip (a request with its creator
// gone no longer makes sense). Everyone who'd joined a dissolved request gets a buddy_alerts
// row; HandleUserLeavingTrip returns those user IDs so callers can push-notify them.
func (s *Service) HandleUserLeavingTrip(ctx context.Context, tripID, userID uuid.UUID) ([]uuid.UUID, error) {
	if err := s.Repo.RemoveUserJoinsInTrip(ctx, tripID, userID); err != nil {
		return nil, err
	}

	requests, err := s.Repo.ListCreatedByUserInTrip(ctx, tripID, userID)
	if err != nil {
		return nil, err
	}

	var alerted []uuid.UUID
	for _, req := range requests {
		joinedUserIDs, err := s.Repo.ListJoins(ctx, req.ID)
		if err != nil {
			return nil, err
		}
		if err := s.Repo.DeleteRequest(ctx, req.ID); err != nil {
			return nil, err
		}
		if len(joinedUserIDs) > 0 {
			if err := s.Repo.CreateAlerts(ctx, tripID, joinedUserIDs); err != nil {
				return nil, err
			}
			alerted = append(alerted, joinedUserIDs...)
		}
	}
	return alerted, nil
}

func (s *Service) HasAlert(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	return s.Repo.HasAlert(ctx, tripID, userID)
}

func (s *Service) ClearAlert(ctx context.Context, tripID, userID uuid.UUID) error {
	return s.Repo.ClearAlert(ctx, tripID, userID)
}
