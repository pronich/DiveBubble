package trip

import (
	"time"

	"github.com/google/uuid"
)

type Trip struct {
	ID        uuid.UUID
	Title     string
	Location  string
	StartTime time.Time
	CreatedAt time.Time
}
