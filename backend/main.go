package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/config"
	"divebubble_be/internal/db"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/message"
	"divebubble_be/internal/push"
	"divebubble_be/internal/realtime"
	"divebubble_be/internal/server"
	"divebubble_be/internal/trip"
)

func main() {
	cfg := config.Load()

	sqlDB, err := db.Open(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer func() {
		if cerr := sqlDB.Close(); cerr != nil {
			log.Printf("database close: %v", cerr)
		}
	}()

	srv := server.New(cfg, sqlDB)

	go runSessionRetention(sqlDB, cfg.SessionRetentionGrace)
	go runFeedbackPromptScan(sqlDB, cfg)

	log.Printf("listening on :%s", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, srv); err != nil {
		log.Fatalf("server: %v", err)
	}
}

// runSessionRetention purges auth_sessions rows past their retention grace period — in-process,
// no separate cron/deploy step. Runs once immediately, then every 24h for the life of the process.
func runSessionRetention(sqlDB *sql.DB, grace time.Duration) {
	sessions := auth.NewSessionRepository(sqlDB)
	cleanup := func() {
		n, err := sessions.DeleteExpired(context.Background(), time.Now().Add(-grace))
		if err != nil {
			log.Printf("session retention cleanup failed: %v", err)
			return
		}
		if n > 0 {
			log.Printf("session retention cleanup: removed %d expired session(s)", n)
		}
	}

	cleanup()
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()
	for range ticker.C {
		cleanup()
	}
}

// runFeedbackPromptScan sends the post-trip feedback system message (in-app + push) once per
// trip whose last day has fully ended — same in-process ticker shape as runSessionRetention,
// no separate cron/deploy step. A trip could wait up to 24h after its last day before the
// prompt appears; shorten the ticker if that turns out to matter.
func runFeedbackPromptScan(sqlDB *sql.DB, cfg config.Config) {
	diveCenterSvc := divecenter.NewService(divecenter.NewRepository(sqlDB))
	tripSvc := trip.NewService(trip.NewRepository(sqlDB), diveCenterSvc)
	messageSvc := message.NewService(message.NewRepository(sqlDB))
	publisher := realtime.NewPublisher(cfg.CentrifugoURL, cfg.CentrifugoAPIKey)
	pushSvc, err := push.New(context.Background(), push.NewRepository(sqlDB), cfg.FirebaseCredentialsJSON)
	if err != nil {
		log.Printf("feedback prompt scan: push disabled, could not init: %v", err)
	}

	cleanup := func() {
		ctx := context.Background()
		tripIDs, err := tripSvc.ListTripIDsAwaitingFeedbackPrompt(ctx)
		if err != nil {
			log.Printf("feedback prompt scan: could not list trips: %v", err)
			return
		}
		sent := 0
		for _, tripID := range tripIDs {
			msg, ok, err := messageSvc.SendSystem(ctx, tripID, message.KindFeedbackPrompt, "How was your trip? We'd love to hear your feedback.")
			if err != nil {
				log.Printf("feedback prompt scan: could not send prompt for trip:%s: %v", tripID, err)
				continue
			}
			if !ok {
				continue
			}
			// Field names kept in sync with messageResponse in internal/server/routes_message.go.
			// feedbackProvided is false for everyone at creation time — each client's next
			// GET /trips/{id}/messages recomputes it correctly per-viewer, same as isDiveCenterStaff.
			payload := map[string]any{
				"id":                 msg.ID,
				"tripId":             msg.TripID,
				"userId":             msg.UserID,
				"body":               msg.Body,
				"createdAt":          msg.CreatedAt,
				"isDiveCenterStaff":  false,
				"mentionsDiveCenter": false,
				"kind":               msg.Kind,
				"feedbackProvided":   false,
			}
			if pubErr := publisher.Publish(ctx, "trip:"+tripID.String(), payload); pubErr != nil {
				log.Printf("feedback prompt scan: realtime publish failed for trip:%s: %v", tripID, pubErr)
			}
			if t, err := tripSvc.GetTrip(ctx, tripID.String()); err != nil {
				log.Printf("feedback prompt scan: could not load trip:%s for push: %v", tripID, err)
			} else if recipients := server.TripRecipientIDs(ctx, tripSvc, diveCenterSvc, t); len(recipients) > 0 {
				pushSvc.SendToUsers(ctx, recipients, push.Notification{
					Title: t.Title,
					Body:  "How was your trip? We'd love to hear your feedback.",
					Data:  map[string]string{"tripId": tripID.String(), "type": "feedback_prompt"},
				})
			}
			sent++
		}
		if sent > 0 {
			log.Printf("feedback prompt scan: sent %d prompt(s)", sent)
		}
	}

	cleanup()
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()
	for range ticker.C {
		cleanup()
	}
}
