package profile

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type Profile struct {
	UserID                uuid.UUID
	DisplayName           sql.NullString
	AvatarURL             sql.NullString
	Location              sql.NullString
	Bio                   sql.NullString
	DiveCount             int
	CertificationLevel    sql.NullString
	CertificationAgency   sql.NullString
	CertificationNumber   sql.NullString
	CertificationPhotoURL sql.NullString
	CertificationVerified bool
	Languages             string // comma-separated, e.g. "English, Russian"
	MemberSince           time.Time
}
