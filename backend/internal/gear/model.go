package gear

import (
	"time"

	"github.com/google/uuid"
)

// Status is app-defined free text ("owned" | "missing" | "rents") — validated on the
// Flutter side against a fixed dictionary, same pattern as certification_level/languages.
type Ownership struct {
	UserID    uuid.UUID
	ItemKey   string
	Status    string
	UpdatedAt time.Time
}
