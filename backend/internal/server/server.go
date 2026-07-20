package server

import (
	"context"
	"database/sql"
	"log"
	"net/http"

	"divebubble_be/internal/account"
	"divebubble_be/internal/auth"
	"divebubble_be/internal/certification"
	"divebubble_be/internal/config"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/email"
	"divebubble_be/internal/gear"
	"divebubble_be/internal/message"
	"divebubble_be/internal/profile"
	"divebubble_be/internal/push"
	"divebubble_be/internal/realtime"
	"divebubble_be/internal/transport"
	"divebubble_be/internal/trip"
	"divebubble_be/internal/upload"
	"divebubble_be/internal/waitlist"
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
	var uploadBackend upload.Backend
	if cfg.SpacesBucket != "" {
		uploadBackend = upload.NewSpacesBackend(cfg.SpacesEndpoint, cfg.SpacesRegion, cfg.SpacesBucket, cfg.SpacesAccessKey, cfg.SpacesSecretKey, cfg.SpacesPublicURL)
	} else {
		uploadBackend = upload.NewLocalBackend(cfg.UploadDir, cfg.PublicBaseURL)
	}
	uploadSvc := upload.NewService(uploadBackend)
	waitlistSvc := waitlist.NewService(waitlist.NewRepository(db))
	accountSvc := account.NewService(account.NewRepository(db))
	pushSvc, err := push.New(context.Background(), push.NewRepository(db), cfg.FirebaseCredentialsJSON)
	if err != nil {
		log.Fatalf("server: push: %v", err)
	}
	publisher := realtime.NewPublisher(cfg.CentrifugoURL, cfg.CentrifugoAPIKey)
	realtimeTokenIssuer := realtime.NewTokenIssuer(cfg.CentrifugoTokenSecret)

	identityRepo := auth.NewIdentityRepository(db)
	sessionRepo := auth.NewSessionRepository(db)
	authIssuer, err := auth.NewTokenIssuer(cfg.JWTSecret, cfg.AccessTokenTTL)
	if err != nil {
		log.Fatalf("server: %v", err)
	}
	appleKeys := auth.NewAppleKeySet()
	emailCodeRepo := auth.NewEmailCodeRepository(db)
	emailSvc := email.New(cfg.ResendAPIKey, cfg.EmailFromAddress)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", handleHealth)
	registerTripRoutes(mux, tripSvc, transportSvc, diveCenterSvc, profileSvc, authIssuer, pushSvc)
	registerMessageRoutes(mux, messageSvc, tripSvc, diveCenterSvc, profileSvc, authIssuer, publisher, pushSvc)
	registerTransportRoutes(mux, transportSvc, tripSvc, diveCenterSvc, profileSvc, authIssuer, pushSvc)
	registerRealtimeRoutes(mux, realtimeTokenIssuer, authIssuer)
	registerAuthRoutes(mux, cfg, identityRepo, sessionRepo, authIssuer, appleKeys, emailCodeRepo, emailSvc)
	registerProfileRoutes(mux, profileSvc, authIssuer)
	registerCertificationRoutes(mux, certificationSvc, authIssuer)
	registerGearRoutes(mux, gearSvc, authIssuer)
	registerUploadRoutes(mux, uploadSvc, profileSvc, tripSvc, certificationSvc, diveCenterSvc, authIssuer)
	registerDiveCenterRoutes(mux, diveCenterSvc, identityRepo, profileSvc, authIssuer)
	registerWaitlistRoutes(mux, waitlistSvc)
	registerAccountRoutes(mux, accountSvc, authIssuer)
	registerPushRoutes(mux, pushSvc, authIssuer)
	// Uploaded images are served back unauthenticated, same as any other image URL
	// referenced from a profile/trip card — dev-only local disk today, swappable for
	// object storage (DigitalOcean Spaces) later without callers noticing.
	mux.Handle("GET /uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir(cfg.UploadDir))))
	return withCORS(cfg.CORSAllowedOrigins, mux)
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}
