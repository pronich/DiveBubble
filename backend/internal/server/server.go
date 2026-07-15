package server

import (
	"database/sql"
	"log"
	"net/http"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/certification"
	"divebubble_be/internal/config"
	"divebubble_be/internal/gear"
	"divebubble_be/internal/message"
	"divebubble_be/internal/profile"
	"divebubble_be/internal/realtime"
	"divebubble_be/internal/transport"
	"divebubble_be/internal/trip"
)

func New(cfg config.Config, db *sql.DB) http.Handler {
	tripRepo := trip.NewRepository(db)
	tripSvc := trip.NewService(tripRepo)
	messageSvc := message.NewService(message.NewRepository(db))
	transportSvc := transport.NewService(transport.NewRepository(db))
	profileSvc := profile.NewService(profile.NewRepository(db))
	certificationSvc := certification.NewService(certification.NewRepository(db))
	gearSvc := gear.NewService(gear.NewRepository(db))
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
	registerTripRoutes(mux, tripSvc, transportSvc, authIssuer)
	registerMessageRoutes(mux, messageSvc, tripSvc, authIssuer, publisher)
	registerTransportRoutes(mux, transportSvc, tripSvc, authIssuer)
	registerRealtimeRoutes(mux, realtimeTokenIssuer, authIssuer)
	registerAuthRoutes(mux, cfg, identityRepo, sessionRepo, authIssuer)
	registerProfileRoutes(mux, profileSvc, authIssuer)
	registerCertificationRoutes(mux, certificationSvc, authIssuer)
	registerGearRoutes(mux, gearSvc, authIssuer)
	return mux
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}
