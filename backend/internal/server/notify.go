package server

import (
	"context"
	"log"

	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

// TripRecipientIDs is everyone with access to a trip (participants plus, for business trips, dive center staff); exported so main.go's feedback-prompt scan job can reuse it.
func TripRecipientIDs(ctx context.Context, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, t trip.Trip) []uuid.UUID {
	recipients, err := tripSvc.ListParticipantUserIDs(ctx, t.ID.String())
	if err != nil {
		log.Printf("push: could not list participants for trip:%s: %v", t.ID, err)
		recipients = nil
	}
	if t.DiveCenterID.Valid {
		staffIDs, err := diveCenterSvc.ListMemberUserIDs(ctx, t.DiveCenterID.UUID)
		if err != nil {
			log.Printf("push: could not list dive center staff for trip:%s: %v", t.ID, err)
		} else {
			recipients = append(recipients, staffIDs...)
		}
	}
	return dedupeUsers(recipients)
}

func dedupeUsers(ids []uuid.UUID) []uuid.UUID {
	seen := make(map[uuid.UUID]bool, len(ids))
	out := make([]uuid.UUID, 0, len(ids))
	for _, id := range ids {
		if seen[id] {
			continue
		}
		seen[id] = true
		out = append(out, id)
	}
	return out
}

// excludeUser filters in place, safe only because its callers always pass a freshly allocated slice.
func excludeUser(ids []uuid.UUID, exclude uuid.UUID) []uuid.UUID {
	out := ids[:0]
	for _, id := range ids {
		if id != exclude {
			out = append(out, id)
		}
	}
	return out
}

// excludeUsers is excludeUser for a set, safe to call with a nil/empty exclude set.
func excludeUsers(ids []uuid.UUID, exclude []uuid.UUID) []uuid.UUID {
	if len(exclude) == 0 {
		return ids
	}
	excludeSet := make(map[uuid.UUID]bool, len(exclude))
	for _, id := range exclude {
		excludeSet[id] = true
	}
	out := ids[:0]
	for _, id := range ids {
		if !excludeSet[id] {
			out = append(out, id)
		}
	}
	return out
}
