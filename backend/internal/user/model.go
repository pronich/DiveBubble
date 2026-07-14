package user

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID          uuid.UUID
	CreatedAt   time.Time
	AccountType string // "individual" | "dive_center" — always "individual" until dive-center onboarding exists
}
