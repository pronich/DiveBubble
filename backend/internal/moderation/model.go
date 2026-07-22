package moderation

import (
	"time"

	"github.com/google/uuid"
)

type Report struct {
	ID             uuid.UUID
	ReporterUserID uuid.UUID
	MessageID      uuid.UUID
	TripID         uuid.UUID
	Reason         string
	Details        string
	CreatedAt      time.Time
}

type Block struct {
	ID            uuid.UUID
	BlockerUserID uuid.UUID
	BlockedUserID uuid.UUID
	CreatedAt     time.Time
}
