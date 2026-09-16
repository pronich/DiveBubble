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

// CreateParams optional fields are nil pointers when not provided, same convention as trip.CreateParams.
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

// Create inserts the dive center and the owner's membership row together in one transaction, so one never exists without the other.
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

// UpdateParams uses pointers so a nil field is left unchanged (same COALESCE convention as trip.UpdateParams/profile.UpdateParams); Name is required, so an empty request means "don't touch it" at the service layer instead.
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

// ListMembers joins users and auth_identities to surface each teammate's email, which isn't a new disclosure since members are only ever added via exact-email search, using LEFT JOIN so a member without an identity row yet doesn't vanish.
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

// ListMemberUserIDs is the lightweight counterpart to ListMembers, skipping user/profile joins for callers like push fan-out that only need who to reach, not who they are.
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

// CreateOrRefreshInvitation upserts on (dive_center_id, email), so re-inviting a pending or previously-accepted email just refreshes the role/timestamps and resets accepted_at rather than erroring.
func (r *Repository) CreateOrRefreshInvitation(ctx context.Context, diveCenterID uuid.UUID, email, role string, invitedByUserID uuid.UUID) (Invitation, error) {
	var inv Invitation
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO dive_center_invitations (dive_center_id, email, role, invited_by_user_id)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (dive_center_id, email) DO UPDATE SET
			role = EXCLUDED.role,
			invited_by_user_id = EXCLUDED.invited_by_user_id,
			created_at = now(),
			accepted_at = NULL
		RETURNING id, dive_center_id, email, role, invited_by_user_id, created_at, accepted_at
	`, diveCenterID, email, role, invitedByUserID).Scan(
		&inv.ID, &inv.DiveCenterID, &inv.Email, &inv.Role, &inv.InvitedByUserID, &inv.CreatedAt, &inv.AcceptedAt,
	)
	return inv, err
}

// ConsumeInvitationsForEmail adds userID to every dive center with a pending invitation for email and marks each accepted, using ON CONFLICT DO NOTHING (not AddMember's DO-UPDATE) so it never downgrades a role an owner has since set manually.
func (r *Repository) ConsumeInvitationsForEmail(ctx context.Context, email string, userID uuid.UUID) error {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, dive_center_id, role FROM dive_center_invitations
		WHERE email = $1 AND accepted_at IS NULL
	`, email)
	if err != nil {
		return err
	}
	type pending struct {
		id           uuid.UUID
		diveCenterID uuid.UUID
		role         string
	}
	var invitations []pending
	for rows.Next() {
		var p pending
		if err := rows.Scan(&p.id, &p.diveCenterID, &p.role); err != nil {
			rows.Close()
			return err
		}
		invitations = append(invitations, p)
	}
	if err := rows.Err(); err != nil {
		return err
	}
	rows.Close()

	for _, p := range invitations {
		if _, err := r.DB.ExecContext(ctx, `
			INSERT INTO dive_center_members (dive_center_id, user_id, role)
			VALUES ($1, $2, $3)
			ON CONFLICT (dive_center_id, user_id) DO NOTHING
		`, p.diveCenterID, userID, p.role); err != nil {
			return err
		}
		if _, err := r.DB.ExecContext(ctx, `
			UPDATE dive_center_invitations SET accepted_at = now() WHERE id = $1
		`, p.id); err != nil {
			return err
		}
	}
	return nil
}
