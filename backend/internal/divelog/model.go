package divelog

import (
	"time"

	"github.com/google/uuid"
)

type Source string

const (
	SourceManual   Source = "manual"
	SourceImported Source = "imported"
)

// ProfileSample is one point on the depth/temperature graph — only ever present on an
// imported entry, never a manual one (there's no instrument data to build it from).
type ProfileSample struct {
	OffsetSeconds int      `json:"offsetSeconds"`
	DepthM        float64  `json:"depthM"`
	TemperatureC  *float64 `json:"temperatureC,omitempty"`
}

type Entry struct {
	ID              uuid.UUID
	UserID          uuid.UUID
	TripID          uuid.NullUUID
	Source          Source
	DivedAt         time.Time
	MaxDepthM       *float64
	AvgDepthM       *float64
	DurationMinutes *int
	MinTemperatureC *float64
	Country         *string
	SiteName        *string
	Latitude        *float64
	Longitude       *float64
	Notes           *string
	ProfileSamples  []ProfileSample
	CreatedAt       time.Time
}
