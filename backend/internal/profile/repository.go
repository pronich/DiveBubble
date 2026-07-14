package profile

import (
	"context"
	"database/sql"

	"github.com/google/uuid"
)

type Repository struct {
	DB *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{DB: db}
}

const profileColumns = `id, display_name, avatar_url, location, bio, dive_count, certification_level, languages, created_at`

func scanProfile(row interface{ Scan(...any) error }) (Profile, error) {
	var p Profile
	err := row.Scan(
		&p.UserID, &p.DisplayName, &p.AvatarURL, &p.Location, &p.Bio,
		&p.DiveCount, &p.CertificationLevel, &p.Languages, &p.MemberSince,
	)
	return p, err
}

func (r *Repository) Get(ctx context.Context, userID uuid.UUID) (Profile, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT `+profileColumns+` FROM users WHERE id = $1`, userID)
	return scanProfile(row)
}

// UpdateParams uses pointers so a nil field is left unchanged rather than cleared.
type UpdateParams struct {
	DisplayName        *string
	AvatarURL          *string
	Location           *string
	Bio                *string
	DiveCount          *int
	CertificationLevel *string
	Languages          *string
}

func (r *Repository) Update(ctx context.Context, userID uuid.UUID, params UpdateParams) (Profile, error) {
	row := r.DB.QueryRowContext(ctx, `
		UPDATE users SET
			display_name = COALESCE($2, display_name),
			avatar_url = COALESCE($3, avatar_url),
			location = COALESCE($4, location),
			bio = COALESCE($5, bio),
			dive_count = COALESCE($6, dive_count),
			certification_level = COALESCE($7, certification_level),
			languages = COALESCE($8, languages)
		WHERE id = $1
		RETURNING `+profileColumns,
		userID, params.DisplayName, params.AvatarURL, params.Location, params.Bio,
		params.DiveCount, params.CertificationLevel, params.Languages,
	)
	return scanProfile(row)
}
