package server

import (
	"context"
	"log"

	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/trip"

	"github.com/google/uuid"
)

// tripRecipientIDs is everyone with access to a trip — participants always, plus a business
// trip's dive center staff. Shared by every trip-level push notification (cancelled, details
// changed, participant joined); message pushes have their own narrower rule (see
// notifyNewMessage's mention gate in routes_message.go) so they don't use this directly.
func tripRecipientIDs(ctx context.Context, tripSvc *trip.Service, diveCenterSvc *divecenter.Service, t trip.Trip) []uuid.UUID {
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

// excludeUser filters in place — safe because dedupeUsers above (the only realistic caller)
// always hands back a freshly allocated slice, never one another caller still holds onto.
func excludeUser(ids []uuid.UUID, exclude uuid.UUID) []uuid.UUID {
	out := ids[:0]
	for _, id := range ids {
		if id != exclude {
			out = append(out, id)
		}
	}
	return out
}
