package divecenter

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type DiveCenter struct {
	ID   uuid.UUID
	Name string

	// Profile fields collected during onboarding — see CLAUDE.md's Business / dive centers section for why each made the MVP cut.
	Location     sql.NullString
	Description  sql.NullString
	LogoURL      sql.NullString
	Agency       sql.NullString
	AgencyDetail sql.NullString
	Languages    string // comma-separated, matching users.languages
	Website      sql.NullString
	Phone        sql.NullString
	Email        sql.NullString

	CreatedAt time.Time
}

type Member struct {
	DiveCenterID uuid.UUID
	UserID       uuid.UUID
	Role         string // "owner" | "staff"
	JoinedAt     time.Time
}

// MemberView is Member enriched with identity/profile data for admin/'s roster screen, joining directly into users/auth_identities rather than round-tripping through those packages' services.
type MemberView struct {
	Member
	DisplayName        sql.NullString
	AvatarURL          sql.NullString
	CertificationLevel sql.NullString
	Email              sql.NullString
}

// MembershipView pairs a dive center with the caller's own role in it, what ListMine returns since both are always asked together.
type MembershipView struct {
	DiveCenter DiveCenter
	Role       string
}

// Invitation is a pending staff invite for an email with no DiveBubble account yet, with no token of its own since a matching sign-in is the proof of ownership (see Service.AcceptInvitations).
type Invitation struct {
	ID              uuid.UUID
	DiveCenterID    uuid.UUID
	Email           string
	Role            string // "owner" | "staff"
	InvitedByUserID uuid.UUID
	CreatedAt       time.Time
	AcceptedAt      sql.NullTime
}
