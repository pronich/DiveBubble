package divecenter

import (
	"context"
	"database/sql"
	"errors"
	"strings"

	"github.com/google/uuid"
)

var ErrNotFound = errors.New("dive center not found")

var diveCenterColumnNames = []string{
	"id", "name", "location", "description", "logo_url",
	"agency", "agency_detail", "languages", "website", "phone", "email", "created_at",
}

var diveCenterColumns = strings.Join(diveCenterColumnNames, ", ")

func diveCenterColumnsPrefixed(alias string) string {
	prefixed := make([]string, len(diveCenterColumnNames))
	for i, c := range diveCenterColumnNames {
		prefixed[i] = alias + "." + c
	}
	return strings.Join(prefixed, ", ")
}

func scanDiveCenter(row interface{ Scan(...any) error }) (DiveCenter, error) {
	var dc DiveCenter
	err := row.Scan(
		&dc.ID, &dc.Name, &dc.Location, &dc.Description, &dc.LogoURL,
		&dc.Agency, &dc.AgencyDetail, &dc.Languages, &dc.Website, &dc.Phone, &dc.Email, &dc.CreatedAt,
	)
	return dc, err
}

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

// CreateParams — optional fields are nil pointers when not provided, same convention as
// trip.CreateParams.
type CreateParams struct {
	Name         string
	Location     *string
	Description  *string
	LogoURL      *string
	Agency       *string
	AgencyDetail *string
	Languages    *string
	Website      *string
	Phone        *string
	Email        *string
}

// Create and the owner's membership row happen together — a dive center with zero owners
// would be immediately unmanageable, so there's never a moment where one exists without the other.
func (r *Repository) Create(ctx context.Context, p CreateParams, ownerUserID uuid.UUID) (DiveCenter, error) {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return DiveCenter{}, err
	}
	defer func() { _ = tx.Rollback() }()

	dc, err := scanDiveCenter(tx.QueryRowContext(ctx, `
		INSERT INTO dive_centers (name, location, description, logo_url, agency, agency_detail, languages, website, phone, email)
		VALUES ($1, $2, $3, $4, $5, $6, COALESCE($7, ''), $8, $9, $10)
		RETURNING `+diveCenterColumns,
		p.Name, p.Location, p.Description, p.LogoURL, p.Agency, p.AgencyDetail, p.Languages, p.Website, p.Phone, p.Email,
	))
	if err != nil {
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
	dc, err := scanDiveCenter(r.DB.QueryRowContext(ctx, `
		SELECT `+diveCenterColumns+` FROM dive_centers WHERE id = $1
	`, id))
	if errors.Is(err, sql.ErrNoRows) {
		return DiveCenter{}, ErrNotFound
	}
	return dc, err
}

func (r *Repository) ListByUser(ctx context.Context, userID uuid.UUID) ([]MembershipView, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+diveCenterColumnsPrefixed("dc")+`, dcm.role
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
		dc := &v.DiveCenter
		if err := rows.Scan(
			&dc.ID, &dc.Name, &dc.Location, &dc.Description, &dc.LogoURL,
			&dc.Agency, &dc.AgencyDetail, &dc.Languages, &dc.Website, &dc.Phone, &dc.Email, &dc.CreatedAt,
			&v.Role,
		); err != nil {
			return nil, err
		}
		views = append(views, v)
	}
	return views, rows.Err()
}

func (r *Repository) SetLogoURL(ctx context.Context, id uuid.UUID, url string) error {
	_, err := r.DB.ExecContext(ctx, `UPDATE dive_centers SET logo_url = $1 WHERE id = $2`, url, id)
	return err
}

// UpdateParams uses pointers so a nil field is left unchanged rather than cleared — same
// COALESCE convention (and same can't-null-an-optional-field-back-out limitation) as
// trip.UpdateParams/profile.UpdateParams. Name excluded from the pointer treatment: it's
// required, so an empty request just means "don't touch it" at the service layer instead.
type UpdateParams struct {
	Name         *string
	Location     *string
	Description  *string
	Agency       *string
	AgencyDetail *string
	Languages    *string
	Website      *string
	Phone        *string
	Email        *string
}

func (r *Repository) Update(ctx context.Context, id uuid.UUID, p UpdateParams) (DiveCenter, error) {
	return scanDiveCenter(r.DB.QueryRowContext(ctx, `
		UPDATE dive_centers SET
			name = COALESCE($2, name),
			location = COALESCE($3, location),
			description = COALESCE($4, description),
			agency = COALESCE($5, agency),
			agency_detail = COALESCE($6, agency_detail),
			languages = COALESCE($7, languages),
			website = COALESCE($8, website),
			phone = COALESCE($9, phone),
			email = COALESCE($10, email)
		WHERE id = $1
		RETURNING `+diveCenterColumns,
		id, p.Name, p.Location, p.Description, p.Agency, p.AgencyDetail, p.Languages, p.Website, p.Phone, p.Email,
	))
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

// ListMembers joins users (display_name/avatar_url/certification_level) and, since a
// member can only ever have been added via the exact-email search in the first place (see
// FindUserIDByEmail), auth_identities (provider_email) — an owner viewing their own
// roster already knows every teammate's email, so surfacing it back here isn't a new
// disclosure. LEFT JOIN on auth_identities: a user could in principle have none yet
// (identity rows aren't created until first login), so a member row shouldn't vanish for it.
func (r *Repository) ListMembers(ctx context.Context, diveCenterID uuid.UUID) ([]MemberView, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT dcm.dive_center_id, dcm.user_id, dcm.role, dcm.joined_at,
			u.display_name, u.avatar_url, u.certification_level, ai.provider_email
		FROM dive_center_members dcm
		JOIN users u ON u.id = dcm.user_id
		LEFT JOIN auth_identities ai ON ai.user_id = dcm.user_id
		WHERE dcm.dive_center_id = $1
		ORDER BY dcm.joined_at ASC
	`, diveCenterID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	members := []MemberView{}
	for rows.Next() {
		var m MemberView
		if err := rows.Scan(
			&m.DiveCenterID, &m.UserID, &m.Role, &m.JoinedAt,
			&m.DisplayName, &m.AvatarURL, &m.CertificationLevel, &m.Email,
		); err != nil {
			return nil, err
		}
		members = append(members, m)
	}
	return members, rows.Err()
}

// ListMemberUserIDs is the lightweight counterpart to ListMembers — no user/profile joins,
// for callers that only need who to reach (e.g. push notification fan-out), not who they are.
func (r *Repository) ListMemberUserIDs(ctx context.Context, diveCenterID uuid.UUID) ([]uuid.UUID, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT user_id FROM dive_center_members WHERE dive_center_id = $1`, diveCenterID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
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
