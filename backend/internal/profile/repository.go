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

const profileColumns = `id, display_name, avatar_url, location, bio, dive_count, certification_level, certification_agency, certification_number, certification_photo_url, certification_verified, languages, created_at`

func scanProfile(row interface{ Scan(...any) error }) (Profile, error) {
	var p Profile
	err := row.Scan(
		&p.UserID, &p.DisplayName, &p.AvatarURL, &p.Location, &p.Bio,
		&p.DiveCount, &p.CertificationLevel, &p.CertificationAgency, &p.CertificationNumber,
		&p.CertificationPhotoURL, &p.CertificationVerified, &p.Languages, &p.MemberSince,
	)
	return p, err
}

func (r *Repository) Get(ctx context.Context, userID uuid.UUID) (Profile, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT `+profileColumns+` FROM users WHERE id = $1`, userID)
	return scanProfile(row)
}

// UpdateParams uses pointers so a nil field is left unchanged rather than cleared.
type UpdateParams struct {
	DisplayName           *string
	AvatarURL             *string
	Location              *string
	Bio                   *string
	DiveCount             *int
	CertificationLevel    *string
	CertificationAgency   *string
	CertificationNumber   *string
	CertificationPhotoURL *string
	CertificationVerified *bool
	Languages             *string
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
			certification_agency = COALESCE($8, certification_agency),
			certification_number = COALESCE($9, certification_number),
			certification_photo_url = COALESCE($10, certification_photo_url),
			certification_verified = COALESCE($11, certification_verified),
			languages = COALESCE($12, languages)
		WHERE id = $1
		RETURNING `+profileColumns,
		userID, params.DisplayName, params.AvatarURL, params.Location, params.Bio,
		params.DiveCount, params.CertificationLevel, params.CertificationAgency,
		params.CertificationNumber, params.CertificationPhotoURL, params.CertificationVerified,
		params.Languages,
	)
	return scanProfile(row)
}
