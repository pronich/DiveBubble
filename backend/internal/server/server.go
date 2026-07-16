package server

import (
	"database/sql"
	"log"
	"net/http"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/certification"
	"divebubble_be/internal/config"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/gear"
	"divebubble_be/internal/message"
	"divebubble_be/internal/profile"
	"divebubble_be/internal/realtime"
	"divebubble_be/internal/transport"
	"divebubble_be/internal/trip"
	"divebubble_be/internal/upload"
)

func New(cfg config.Config, db *sql.DB) http.Handler {
	diveCenterSvc := divecenter.NewService(divecenter.NewRepository(db))
	tripRepo := trip.NewRepository(db)
	tripSvc := trip.NewService(tripRepo, diveCenterSvc)
	messageSvc := message.NewService(message.NewRepository(db))
	transportSvc := transport.NewService(transport.NewRepository(db))
	profileSvc := profile.NewService(profile.NewRepository(db))
	certificationSvc := certification.NewService(certification.NewRepository(db))
	gearSvc := gear.NewService(gear.NewRepository(db))
	uploadSvc := upload.NewService(cfg.UploadDir, cfg.PublicBaseURL)
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
	registerUploadRoutes(mux, uploadSvc, profileSvc, tripSvc, certificationSvc, diveCenterSvc, authIssuer)
	registerDiveCenterRoutes(mux, diveCenterSvc, identityRepo, profileSvc, authIssuer)
	// Uploaded images are served back unauthenticated, same as any other image URL
	// referenced from a profile/trip card — dev-only local disk today, swappable for
	// object storage (DigitalOcean Spaces) later without callers noticing.
	mux.Handle("GET /uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir(cfg.UploadDir))))
	return withCORS(cfg.CORSAllowedOrigins, mux)
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}
