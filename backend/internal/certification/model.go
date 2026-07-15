package certification

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type Specialty struct {
	ID          uuid.UUID
	UserID      uuid.UUID
	Specialty   string
	CustomLabel sql.NullString
	Agency      sql.NullString
	CertNumber  sql.NullString
	PhotoURL    sql.NullString
	Verified    bool
	CreatedAt   time.Time
}
