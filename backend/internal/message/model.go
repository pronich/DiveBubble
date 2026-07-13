package message

import (
	"time"

	"github.com/google/uuid"
)

type Message struct {
	ID        uuid.UUID
	TripID    uuid.UUID
	UserID    uuid.UUID
	Body      string
	CreatedAt time.Time
}
