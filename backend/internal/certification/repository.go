package certification

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

const specialtyColumns = `id, user_id, specialty, custom_label, agency, cert_number, photo_url, verified, created_at`

func scanSpecialty(row interface{ Scan(...any) error }) (Specialty, error) {
	var s Specialty
	err := row.Scan(
		&s.ID, &s.UserID, &s.Specialty, &s.CustomLabel, &s.Agency,
		&s.CertNumber, &s.PhotoURL, &s.Verified, &s.CreatedAt,
	)
	return s, err
}

type CreateParams struct {
	Specialty   string
	CustomLabel *string
	Agency      *string
	CertNumber  *string
}

func (r *Repository) Create(ctx context.Context, userID uuid.UUID, params CreateParams) (Specialty, error) {
	row := r.DB.QueryRowContext(ctx, `
		INSERT INTO specialty_certifications (user_id, specialty, custom_label, agency, cert_number)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING `+specialtyColumns,
		userID, params.Specialty, params.CustomLabel, params.Agency, params.CertNumber,
	)
	return scanSpecialty(row)
}

func (r *Repository) ListByUser(ctx context.Context, userID uuid.UUID) ([]Specialty, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT `+specialtyColumns+`
		FROM specialty_certifications
		WHERE user_id = $1
		ORDER BY created_at ASC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	specialties := []Specialty{}
	for rows.Next() {
		s, err := scanSpecialty(rows)
		if err != nil {
			return nil, err
		}
		specialties = append(specialties, s)
	}
	return specialties, rows.Err()
}

// SetPhotoURL returns false (no error) if no row matched — same ownership-scoped shape as Delete.
func (r *Repository) SetPhotoURL(ctx context.Context, id, userID uuid.UUID, url string) (bool, error) {
	res, err := r.DB.ExecContext(ctx, `
		UPDATE specialty_certifications SET photo_url = $1 WHERE id = $2 AND user_id = $3
	`, url, id, userID)
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	return n > 0, err
}

// Delete returns false (no error) if no row matched — either it didn't exist or belonged to another user.
func (r *Repository) Delete(ctx context.Context, userID, id uuid.UUID) (bool, error) {
	res, err := r.DB.ExecContext(ctx, `
		DELETE FROM specialty_certifications WHERE id = $1 AND user_id = $2
	`, id, userID)
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	return n > 0, err
}
