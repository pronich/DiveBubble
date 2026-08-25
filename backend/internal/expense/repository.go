package expense

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
)

var ErrNotFound = errors.New("expense not found")

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

const expenseColumns = `id, trip_id, payer_user_id, created_by, title, amount_minor, split_type, created_at, updated_at`

func scanExpense(row interface{ Scan(...any) error }, e *Expense) error {
	return row.Scan(&e.ID, &e.TripID, &e.PayerUserID, &e.CreatedBy, &e.Title, &e.AmountMinor, &e.SplitType, &e.CreatedAt, &e.UpdatedAt)
}

type CreateParams struct {
	TripID      uuid.UUID
	PayerUserID uuid.UUID
	CreatedBy   uuid.UUID
	Title       string
	AmountMinor int64
	SplitType   SplitType
	Shares      []Share
}

// Create inserts the expense and its per-participant shares in one transaction — a half-
// written expense (row present, no shares) would silently break every balance computed
// afterward, so this either lands both or neither.
func (r *Repository) Create(ctx context.Context, p CreateParams) (Expense, error) {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return Expense{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var e Expense
	if err := scanExpense(tx.QueryRowContext(ctx, `
		INSERT INTO trip_expenses (trip_id, payer_user_id, created_by, title, amount_minor, split_type)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING `+expenseColumns+`
	`, p.TripID, p.PayerUserID, p.CreatedBy, p.Title, p.AmountMinor, p.SplitType), &e); err != nil {
		return Expense{}, err
	}

	if err := insertShares(ctx, tx, e.ID, p.Shares); err != nil {
		return Expense{}, err
	}
	e.Shares = p.Shares

	if err := tx.Commit(); err != nil {
		return Expense{}, err
	}
	return e, nil
}

type UpdateParams struct {
	PayerUserID uuid.UUID
	Title       string
	AmountMinor int64
	SplitType   SplitType
	Shares      []Share
}

// Update replaces the expense's fields and its entire share set (simpler and less error-prone
// than diffing old vs new shares — a trip has at most a handful of participants, so a full
// delete+reinsert is cheap).
func (r *Repository) Update(ctx context.Context, id uuid.UUID, p UpdateParams) (Expense, error) {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return Expense{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var e Expense
	if err := scanExpense(tx.QueryRowContext(ctx, `
		UPDATE trip_expenses
		SET payer_user_id = $2, title = $3, amount_minor = $4, split_type = $5, updated_at = now()
		WHERE id = $1
		RETURNING `+expenseColumns+`
	`, id, p.PayerUserID, p.Title, p.AmountMinor, p.SplitType), &e); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Expense{}, ErrNotFound
		}
		return Expense{}, err
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM trip_expense_shares WHERE expense_id = $1`, id); err != nil {
		return Expense{}, err
	}
	if err := insertShares(ctx, tx, id, p.Shares); err != nil {
		return Expense{}, err
	}
	e.Shares = p.Shares

	if err := tx.Commit(); err != nil {
		return Expense{}, err
	}
	return e, nil
}

func insertShares(ctx context.Context, tx *sql.Tx, expenseID uuid.UUID, shares []Share) error {
	for _, s := range shares {
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO trip_expense_shares (expense_id, user_id, shares, amount_minor)
			VALUES ($1, $2, $3, $4)
		`, expenseID, s.UserID, s.Shares, s.AmountMinor); err != nil {
			return err
		}
	}
	return nil
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (Expense, error) {
	var e Expense
	if err := scanExpense(r.DB.QueryRowContext(ctx, `
		SELECT `+expenseColumns+` FROM trip_expenses WHERE id = $1
	`, id), &e); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Expense{}, ErrNotFound
		}
		return Expense{}, err
	}

	shares, err := r.listSharesByExpenseIDs(ctx, []uuid.UUID{e.ID})
	if err != nil {
		return Expense{}, err
	}
	e.Shares = shares[e.ID]
	return e, nil
}

// ListByTrip returns every expense on the trip, most recent first, with shares populated —
// same batch-not-N+1 shape as message.Repository.ListAttachmentsByMessageIDs.
func (r *Repository) ListByTrip(ctx context.Context, tripID uuid.UUID) ([]Expense, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+expenseColumns+` FROM trip_expenses WHERE trip_id = $1 ORDER BY created_at DESC
	`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	expenses := []Expense{}
	ids := []uuid.UUID{}
	for rows.Next() {
		var e Expense
		if err := scanExpense(rows, &e); err != nil {
			return nil, err
		}
		expenses = append(expenses, e)
		ids = append(ids, e.ID)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	sharesByExpense, err := r.listSharesByExpenseIDs(ctx, ids)
	if err != nil {
		return nil, err
	}
	for i := range expenses {
		expenses[i].Shares = sharesByExpense[expenses[i].ID]
	}
	return expenses, nil
}

func (r *Repository) listSharesByExpenseIDs(ctx context.Context, expenseIDs []uuid.UUID) (map[uuid.UUID][]Share, error) {
	out := map[uuid.UUID][]Share{}
	if len(expenseIDs) == 0 {
		return out, nil
	}
	rows, err := r.DB.QueryContext(ctx, `
		SELECT expense_id, user_id, shares, amount_minor
		FROM trip_expense_shares
		WHERE expense_id = ANY($1)
	`, expenseIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var expenseID uuid.UUID
		var s Share
		var shareCount sql.NullInt32
		if err := rows.Scan(&expenseID, &s.UserID, &shareCount, &s.AmountMinor); err != nil {
			return nil, err
		}
		if shareCount.Valid {
			v := int(shareCount.Int32)
			s.Shares = &v
		}
		out[expenseID] = append(out[expenseID], s)
	}
	return out, rows.Err()
}

func (r *Repository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM trip_expenses WHERE id = $1`, id)
	return err
}

type CreateSettlementParams struct {
	TripID      uuid.UUID
	FromUserID  uuid.UUID
	ToUserID    uuid.UUID
	AmountMinor int64
}

func (r *Repository) CreateSettlement(ctx context.Context, p CreateSettlementParams) (Settlement, error) {
	var s Settlement
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO trip_expense_settlements (trip_id, from_user_id, to_user_id, amount_minor)
		VALUES ($1, $2, $3, $4)
		RETURNING id, trip_id, from_user_id, to_user_id, amount_minor, created_at
	`, p.TripID, p.FromUserID, p.ToUserID, p.AmountMinor).Scan(
		&s.ID, &s.TripID, &s.FromUserID, &s.ToUserID, &s.AmountMinor, &s.CreatedAt,
	)
	return s, err
}

func (r *Repository) ListSettlementsByTrip(ctx context.Context, tripID uuid.UUID) ([]Settlement, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, trip_id, from_user_id, to_user_id, amount_minor, created_at
		FROM trip_expense_settlements
		WHERE trip_id = $1
		ORDER BY created_at ASC
	`, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	settlements := []Settlement{}
	for rows.Next() {
		var s Settlement
		if err := rows.Scan(&s.ID, &s.TripID, &s.FromUserID, &s.ToUserID, &s.AmountMinor, &s.CreatedAt); err != nil {
			return nil, err
		}
		settlements = append(settlements, s)
	}
	return settlements, rows.Err()
}
