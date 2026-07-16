package divecenter

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type DiveCenter struct {
	ID   uuid.UUID
	Name string

	// Profile fields, collected during onboarding — see CLAUDE.md's Business / dive
	// centers section for why each one made the MVP cut.
	Location     sql.NullString
	Description  sql.NullString
	LogoURL      sql.NullString
	Agency       sql.NullString
	AgencyDetail sql.NullString
	Languages    string // comma-separated, matching users.languages
	Website      sql.NullString
	Phone        sql.NullString

	CreatedAt time.Time
}

type Member struct {
	DiveCenterID uuid.UUID
	UserID       uuid.UUID
	Role         string // "owner" | "staff"
	JoinedAt     time.Time
}

// MemberView is Member enriched with just enough identity/profile data for a roster
// screen (admin/'s Users page) — a bare Member has nothing a human could recognize a
// teammate by. Joins directly into users/auth_identities (profile/auth's own tables)
// rather than round-tripping through those packages' services, same precedent as
// trip.Repository.ListJoinedByUser's own direct dive_center_members join.
type MemberView struct {
	Member
	DisplayName        sql.NullString
	AvatarURL          sql.NullString
	CertificationLevel sql.NullString
	Email              sql.NullString
}

// MembershipView pairs a dive center with the caller's own role in it — what ListMine
// returns, since "which businesses am I part of, and as what" is always asked together.
type MembershipView struct {
	DiveCenter DiveCenter
	Role       string
}
