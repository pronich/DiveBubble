package server

import (
	"database/sql"
	"log"
	"net/http"

	"divebuddy_be/internal/auth"
	"divebuddy_be/internal/config"
	"divebuddy_be/internal/message"
	"divebuddy_be/internal/realtime"
	"divebuddy_be/internal/transport"
	"divebuddy_be/internal/trip"
)

func New(cfg config.Config, db *sql.DB) http.Handler {
	tripRepo := trip.NewRepository(db)
	tripSvc := trip.NewService(tripRepo)
	messageSvc := message.NewService(message.NewRepository(db))
	transportSvc := transport.NewService(transport.NewRepository(db))
	publisher := realtime.NewPublisher(cfg.CentrifugoURL, cfg.CentrifugoAPIKey)
	realtimeTokenIssuer := realtime.NewTokenIssuer(cfg.CentrifugoTokenSecret)

	identityRepo := auth.NewIdentityRepository(db)
	sessionRepo := auth.NewSessionRepository(db)
	authIssuer, err := auth.NewTokenIssuer(cfg.JWTSecret, cfg.AccessTokenTTL)
	if err != nil {
		log.Fatalf("server: %v", err)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", handleHealth)
	registerTripRoutes(mux, tripSvc, authIssuer)
	registerMessageRoutes(mux, messageSvc, tripSvc, authIssuer, publisher)
	registerTransportRoutes(mux, transportSvc, tripSvc, authIssuer)
	registerRealtimeRoutes(mux, realtimeTokenIssuer, authIssuer)
	registerAuthRoutes(mux, cfg, identityRepo, sessionRepo, authIssuer)
	return mux
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}
