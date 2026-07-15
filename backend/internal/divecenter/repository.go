package divecenter

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
)

var ErrNotFound = errors.New("dive center not found")

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

// Create and the owner's membership row happen together — a dive center with zero owners
// would be immediately unmanageable, so there's never a moment where one exists without the other.
func (r *Repository) Create(ctx context.Context, name string, ownerUserID uuid.UUID) (DiveCenter, error) {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return DiveCenter{}, err
	}
	defer func() { _ = tx.Rollback() }()

	var dc DiveCenter
	if err := tx.QueryRowContext(ctx, `
		INSERT INTO dive_centers (name) VALUES ($1)
		RETURNING id, name, created_at
	`, name).Scan(&dc.ID, &dc.Name, &dc.CreatedAt); err != nil {
		return DiveCenter{}, err
	}

	if _, err := tx.ExecContext(ctx, `
		INSERT INTO dive_center_members (dive_center_id, user_id, role) VALUES ($1, $2, 'owner')
	`, dc.ID, ownerUserID); err != nil {
		return DiveCenter{}, err
	}

	if err := tx.Commit(); err != nil {
		return DiveCenter{}, err
	}
	return dc, nil
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (DiveCenter, error) {
	var dc DiveCenter
	err := r.DB.QueryRowContext(ctx, `
		SELECT id, name, created_at FROM dive_centers WHERE id = $1
	`, id).Scan(&dc.ID, &dc.Name, &dc.CreatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return DiveCenter{}, ErrNotFound
	}
	return dc, err
}

func (r *Repository) ListByUser(ctx context.Context, userID uuid.UUID) ([]MembershipView, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT dc.id, dc.name, dc.created_at, dcm.role
		FROM dive_center_members dcm
		JOIN dive_centers dc ON dc.id = dcm.dive_center_id
		WHERE dcm.user_id = $1
		ORDER BY dcm.joined_at ASC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	views := []MembershipView{}
	for rows.Next() {
		var v MembershipView
		if err := rows.Scan(&v.DiveCenter.ID, &v.DiveCenter.Name, &v.DiveCenter.CreatedAt, &v.Role); err != nil {
			return nil, err
		}
		views = append(views, v)
	}
	return views, rows.Err()
}

func (r *Repository) IsMember(ctx context.Context, diveCenterID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM dive_center_members WHERE dive_center_id = $1 AND user_id = $2)
	`, diveCenterID, userID).Scan(&exists)
	return exists, err
}

func (r *Repository) IsOwner(ctx context.Context, diveCenterID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(ctx, `
		SELECT EXISTS(SELECT 1 FROM dive_center_members WHERE dive_center_id = $1 AND user_id = $2 AND role = 'owner')
	`, diveCenterID, userID).Scan(&exists)
	return exists, err
}

func (r *Repository) ListMembers(ctx context.Context, diveCenterID uuid.UUID) ([]Member, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT dive_center_id, user_id, role, joined_at FROM dive_center_members
		WHERE dive_center_id = $1 ORDER BY joined_at ASC
	`, diveCenterID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	members := []Member{}
	for rows.Next() {
		var m Member
		if err := rows.Scan(&m.DiveCenterID, &m.UserID, &m.Role, &m.JoinedAt); err != nil {
			return nil, err
		}
		members = append(members, m)
	}
	return members, rows.Err()
}

// AddMember upserts — re-adding an existing member just updates their role, rather than erroring.
func (r *Repository) AddMember(ctx context.Context, diveCenterID, userID uuid.UUID, role string) (Member, error) {
	var m Member
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO dive_center_members (dive_center_id, user_id, role)
		VALUES ($1, $2, $3)
		ON CONFLICT (dive_center_id, user_id) DO UPDATE SET role = EXCLUDED.role
		RETURNING dive_center_id, user_id, role, joined_at
	`, diveCenterID, userID, role).Scan(&m.DiveCenterID, &m.UserID, &m.Role, &m.JoinedAt)
	return m, err
}

// RemoveMember returns false (no error) if no row matched.
func (r *Repository) RemoveMember(ctx context.Context, diveCenterID, userID uuid.UUID) (bool, error) {
	res, err := r.DB.ExecContext(ctx, `
		DELETE FROM dive_center_members WHERE dive_center_id = $1 AND user_id = $2
	`, diveCenterID, userID)
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	return n > 0, err
}

func (r *Repository) CountOwners(ctx context.Context, diveCenterID uuid.UUID) (int, error) {
	var count int
	err := r.DB.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM dive_center_members WHERE dive_center_id = $1 AND role = 'owner'
	`, diveCenterID).Scan(&count)
	return count, err
}
