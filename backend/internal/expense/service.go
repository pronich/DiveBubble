package expense

import (
	"context"
	"errors"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
)

var ErrInvalidArgument = errors.New("invalid argument")
var ErrSplitMismatch = errors.New("split amounts do not add up to the total")
var ErrForbidden = errors.New("only the creator can do that")

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

// SplitInput carries whichever field the expense's SplitType actually needs — the other two
// are simply ignored by computeShares.
type SplitInput struct {
	ParticipantUserIDs []uuid.UUID         // SplitEqual
	Shares             map[uuid.UUID]int   // SplitShares — share count per participant, e.g. 1/2/3
	ExactAmountsMinor  map[uuid.UUID]int64 // SplitExact — exact amount per participant, must sum to the total
}

func (s *Service) Create(ctx context.Context, tripID, payerUserID, createdBy uuid.UUID, title string, amountMinor int64, splitType SplitType, occurredAt time.Time, input SplitInput) (Expense, error) {
	title = strings.TrimSpace(title)
	if title == "" || amountMinor <= 0 || !splitType.Valid() {
		return Expense{}, ErrInvalidArgument
	}
	if occurredAt.IsZero() {
		occurredAt = time.Now()
	}
	shares, err := computeShares(splitType, amountMinor, input)
	if err != nil {
		return Expense{}, err
	}
	return s.Repo.Create(ctx, CreateParams{
		TripID: tripID, PayerUserID: payerUserID, CreatedBy: createdBy,
		Title: title, AmountMinor: amountMinor, SplitType: splitType, OccurredAt: occurredAt, Shares: shares,
	})
}

// Update lets any participant re-split or correct an expense (matches the product decision
// that editing is unrestricted, unlike Delete) — CreatedBy never changes, so Delete's
// creator-only check keeps working after an edit by someone else.
func (s *Service) Update(ctx context.Context, id, payerUserID uuid.UUID, title string, amountMinor int64, splitType SplitType, occurredAt time.Time, input SplitInput) (Expense, error) {
	title = strings.TrimSpace(title)
	if title == "" || amountMinor <= 0 || !splitType.Valid() {
		return Expense{}, ErrInvalidArgument
	}
	if occurredAt.IsZero() {
		occurredAt = time.Now()
	}
	shares, err := computeShares(splitType, amountMinor, input)
	if err != nil {
		return Expense{}, err
	}
	return s.Repo.Update(ctx, id, UpdateParams{
		PayerUserID: payerUserID, Title: title, AmountMinor: amountMinor, SplitType: splitType, OccurredAt: occurredAt, Shares: shares,
	})
}

func (s *Service) GetByID(ctx context.Context, id uuid.UUID) (Expense, error) {
	return s.Repo.GetByID(ctx, id)
}

func (s *Service) ListByTrip(ctx context.Context, tripID uuid.UUID) ([]Expense, error) {
	return s.Repo.ListByTrip(ctx, tripID)
}

// Delete removes an expense outright — only its creator may do this (mirrors transport's
// Dissolve). Everyone can edit an expense, but only its author can make it disappear.
func (s *Service) Delete(ctx context.Context, id, callerUserID uuid.UUID) error {
	e, err := s.Repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if e.CreatedBy != callerUserID {
		return ErrForbidden
	}
	return s.Repo.Delete(ctx, id)
}

func (s *Service) CreateSettlement(ctx context.Context, tripID, fromUserID, toUserID uuid.UUID, amountMinor int64) (Settlement, error) {
	if amountMinor <= 0 || fromUserID == toUserID {
		return Settlement{}, ErrInvalidArgument
	}
	return s.Repo.CreateSettlement(ctx, CreateSettlementParams{
		TripID: tripID, FromUserID: fromUserID, ToUserID: toUserID, AmountMinor: amountMinor,
	})
}

// GetBalance nets every expense and settlement on the trip into one balance per user who's
// touched either, then simplifies the debts into the minimum practical set of transfers (see
// Simplify) — the two things the Expenses tab's balance card actually needs.
func (s *Service) GetBalance(ctx context.Context, tripID uuid.UUID) ([]Balance, []SettlementSuggestion, error) {
	expenses, err := s.Repo.ListByTrip(ctx, tripID)
	if err != nil {
		return nil, nil, err
	}
	settlements, err := s.Repo.ListSettlementsByTrip(ctx, tripID)
	if err != nil {
		return nil, nil, err
	}

	net := map[uuid.UUID]int64{}
	for _, e := range expenses {
		net[e.PayerUserID] += e.AmountMinor
		for _, share := range e.Shares {
			net[share.UserID] -= share.AmountMinor
		}
	}
	for _, st := range settlements {
		net[st.FromUserID] += st.AmountMinor
		net[st.ToUserID] -= st.AmountMinor
	}

	balances := make([]Balance, 0, len(net))
	for userID, amount := range net {
		if amount == 0 {
			continue
		}
		balances = append(balances, Balance{UserID: userID, AmountMinor: amount})
	}
	sort.Slice(balances, func(i, j int) bool { return balances[i].UserID.String() < balances[j].UserID.String() })

	return balances, Simplify(balances), nil
}

// Simplify collapses a set of net balances into the minimum practical set of pairwise
// transfers that would bring everyone to zero — greedily matching the largest creditor
// against the largest debtor each round. Not guaranteed globally minimal (that's a harder
// problem for larger groups), but it's the same "good enough" approach Splitwise itself
// uses, and a dive trip's participant count is always small.
func Simplify(balances []Balance) []SettlementSuggestion {
	type entry struct {
		userID uuid.UUID
		amount int64 // always positive within each slice below
	}
	var creditors, debtors []entry
	for _, b := range balances {
		if b.AmountMinor > 0 {
			creditors = append(creditors, entry{b.UserID, b.AmountMinor})
		} else if b.AmountMinor < 0 {
			debtors = append(debtors, entry{b.UserID, -b.AmountMinor})
		}
	}
	sort.Slice(creditors, func(i, j int) bool { return creditors[i].amount > creditors[j].amount })
	sort.Slice(debtors, func(i, j int) bool { return debtors[i].amount > debtors[j].amount })

	var out []SettlementSuggestion
	i, j := 0, 0
	for i < len(creditors) && j < len(debtors) {
		settle := creditors[i].amount
		if debtors[j].amount < settle {
			settle = debtors[j].amount
		}
		out = append(out, SettlementSuggestion{FromUserID: debtors[j].userID, ToUserID: creditors[i].userID, AmountMinor: settle})
		creditors[i].amount -= settle
		debtors[j].amount -= settle
		if creditors[i].amount == 0 {
			i++
		}
		if debtors[j].amount == 0 {
			j++
		}
	}
	return out
}

func computeShares(splitType SplitType, amountMinor int64, input SplitInput) ([]Share, error) {
	switch splitType {
	case SplitEqual:
		if len(input.ParticipantUserIDs) == 0 {
			return nil, ErrInvalidArgument
		}
		return computeEqualSplit(amountMinor, input.ParticipantUserIDs), nil
	case SplitShares:
		return computeSharesSplit(amountMinor, input.Shares)
	case SplitExact:
		return computeExactSplit(amountMinor, input.ExactAmountsMinor)
	default:
		return nil, ErrInvalidArgument
	}
}

// computeEqualSplit divides as evenly as integer minor units allow, then hands the leftover
// pennies (amountMinor % n of them) to participants in a stable, deterministic order — so the
// same input always produces the same split, not one that depends on map/slice iteration order.
func computeEqualSplit(amountMinor int64, participants []uuid.UUID) []Share {
	sorted := append([]uuid.UUID(nil), participants...)
	sort.Slice(sorted, func(i, j int) bool { return sorted[i].String() < sorted[j].String() })

	n := int64(len(sorted))
	base := amountMinor / n
	remainder := amountMinor % n
	shares := make([]Share, len(sorted))
	for i, id := range sorted {
		amt := base
		if int64(i) < remainder {
			amt++
		}
		shares[i] = Share{UserID: id, AmountMinor: amt}
	}
	return shares
}

// computeSharesSplit turns integer share counts (1/2/3 — the "pays for 2" case) into minor
// units proportionally, using the largest-remainder method to hand out leftover pennies to
// whoever's exact proportional amount was closest to rounding up, so the total always matches
// exactly rather than drifting a cent short from truncation.
func computeSharesSplit(amountMinor int64, sharesInput map[uuid.UUID]int) ([]Share, error) {
	if len(sharesInput) == 0 {
		return nil, ErrInvalidArgument
	}
	ids := make([]uuid.UUID, 0, len(sharesInput))
	totalShares := 0
	for id, count := range sharesInput {
		if count <= 0 {
			return nil, ErrInvalidArgument
		}
		ids = append(ids, id)
		totalShares += count
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i].String() < ids[j].String() })

	type computed struct {
		id    uuid.UUID
		count int
		floor int64
		frac  float64
	}
	computedList := make([]computed, len(ids))
	var sumFloor int64
	for i, id := range ids {
		count := sharesInput[id]
		exact := float64(amountMinor) * float64(count) / float64(totalShares)
		floor := int64(exact)
		computedList[i] = computed{id: id, count: count, floor: floor, frac: exact - float64(floor)}
		sumFloor += floor
	}
	leftover := amountMinor - sumFloor
	sort.SliceStable(computedList, func(i, j int) bool { return computedList[i].frac > computedList[j].frac })
	for i := int64(0); i < leftover; i++ {
		computedList[i].floor++
	}

	result := make([]Share, len(computedList))
	for i, c := range computedList {
		count := c.count
		result[i] = Share{UserID: c.id, Shares: &count, AmountMinor: c.floor}
	}
	return result, nil
}

// computeExactSplit takes the caller's own per-participant amounts as-is — the only
// validation needed is that they add up to the total exactly (integer minor units, no
// rounding tolerance to reason about).
func computeExactSplit(amountMinor int64, exactInput map[uuid.UUID]int64) ([]Share, error) {
	if len(exactInput) == 0 {
		return nil, ErrInvalidArgument
	}
	ids := make([]uuid.UUID, 0, len(exactInput))
	var sum int64
	for id, amt := range exactInput {
		if amt < 0 {
			return nil, ErrInvalidArgument
		}
		ids = append(ids, id)
		sum += amt
	}
	if sum != amountMinor {
		return nil, ErrSplitMismatch
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i].String() < ids[j].String() })

	result := make([]Share, len(ids))
	for i, id := range ids {
		result[i] = Share{UserID: id, AmountMinor: exactInput[id]}
	}
	return result, nil
}
