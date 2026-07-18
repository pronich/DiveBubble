package config

import (
	"log"
	"os"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Port                  string
	DatabaseURL           string
	CentrifugoURL         string
	CentrifugoAPIKey      string
	CentrifugoTokenSecret string
	JWTSecret             string
	GoogleServerClientID  string
	// AppleAudience is the iOS app's bundle id (the App ID, not a Services ID — DiveBubble
	// has no web Sign in with Apple flow). Defaults to the one and only bundle id this
	// project ships, so no env var is required in dev.
	AppleAudience string
	AccessTokenTTL        time.Duration
	RefreshSessionTTL     time.Duration
	SessionRetentionGrace time.Duration
	UploadDir             string
	PublicBaseURL         string
	CORSAllowedOrigins    []string

	// Spaces* are all optional — SpacesBucket empty means "use LocalBackend" (dev default,
	// see server.go). Set together in production; there's no partial-Spaces mode.
	SpacesEndpoint  string
	SpacesRegion    string
	SpacesBucket    string
	SpacesAccessKey string
	SpacesSecretKey string
	// SpacesPublicURL is the CDN endpoint if the Space has one enabled, else the same
	// direct https://<bucket>.<region>.digitaloceanspaces.com host — either way, computed
	// once here so callers never re-derive it. No trailing slash.
	SpacesPublicURL string
}

func Load() Config {
	// Local development: load `.env` when present (ignore missing file)
	_ = godotenv.Load()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	databaseURL := require("DATABASE_URL")
	centrifugoURL := require("CENTRIFUGO_URL")
	centrifugoAPIKey := require("CENTRIFUGO_API_KEY")
	centrifugoTokenSecret := require("CENTRIFUGO_TOKEN_SECRET")
	jwtSecret := require("JWT_SECRET")
	googleServerClientID := require("GOOGLE_SERVER_CLIENT_ID")
	appleAudience := os.Getenv("APPLE_AUDIENCE")
	if appleAudience == "" {
		appleAudience = "io.divebubble.app"
	}
	accessTokenTTL := durationEnv("ACCESS_TOKEN_TTL", 8*time.Hour)
	refreshSessionTTL := durationEnv("REFRESH_SESSION_TTL", 180*24*time.Hour)
	// How long an expired/revoked auth_sessions row is kept before physical deletion —
	// separate from RefreshSessionTTL, which only governs how long the token stays usable.
	sessionRetentionGrace := durationEnv("SESSION_RETENTION_GRACE", 30*24*time.Hour)

	uploadDir := os.Getenv("UPLOAD_DIR")
	if uploadDir == "" {
		uploadDir = "./uploads"
	}
	// What the client uses to build a full image URL from the relative path Save()
	// returns — must be reachable from the device/simulator, not just the server host.
	publicBaseURL := os.Getenv("PUBLIC_BASE_URL")
	if publicBaseURL == "" {
		publicBaseURL = "http://localhost:" + port
	}

	// "*" by default — safe for Bearer-token auth (no cookies/credentials involved), and
	// local dev's Flutter web port varies run to run. Set explicitly in production.
	corsAllowedOrigins := []string{"*"}
	if raw := os.Getenv("CORS_ALLOWED_ORIGINS"); raw != "" {
		corsAllowedOrigins = strings.Split(raw, ",")
	}

	spacesEndpoint := os.Getenv("SPACES_ENDPOINT")
	spacesRegion := os.Getenv("SPACES_REGION")
	spacesBucket := os.Getenv("SPACES_BUCKET")
	spacesAccessKey := os.Getenv("SPACES_ACCESS_KEY")
	spacesSecretKey := os.Getenv("SPACES_SECRET_KEY")
	spacesPublicURL := strings.TrimSuffix(os.Getenv("SPACES_CDN_URL"), "/")
	if spacesPublicURL == "" && spacesBucket != "" {
		// No CDN configured — fall back to the direct virtual-hosted-style Space URL,
		// derived from the endpoint (e.g. https://fra1.digitaloceanspaces.com) + bucket.
		spacesPublicURL = strings.Replace(spacesEndpoint, "https://", "https://"+spacesBucket+".", 1)
	}

	return Config{
		Port:                  port,
		DatabaseURL:           databaseURL,
		CentrifugoURL:         centrifugoURL,
		CentrifugoAPIKey:      centrifugoAPIKey,
		CentrifugoTokenSecret: centrifugoTokenSecret,
		JWTSecret:             jwtSecret,
		GoogleServerClientID:  googleServerClientID,
		AppleAudience:         appleAudience,
		AccessTokenTTL:        accessTokenTTL,
		RefreshSessionTTL:     refreshSessionTTL,
		SessionRetentionGrace: sessionRetentionGrace,
		UploadDir:             uploadDir,
		PublicBaseURL:         publicBaseURL,
		CORSAllowedOrigins:    corsAllowedOrigins,
		SpacesEndpoint:        spacesEndpoint,
		SpacesRegion:          spacesRegion,
		SpacesBucket:          spacesBucket,
		SpacesAccessKey:       spacesAccessKey,
		SpacesSecretKey:       spacesSecretKey,
		SpacesPublicURL:       spacesPublicURL,
	}
}

func require(key string) string {
	v := os.Getenv(key)
	if strings.TrimSpace(v) == "" {
		log.Fatalf("config: %s is required", key)
	}
	return v
}

func durationEnv(key string, fallback time.Duration) time.Duration {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return fallback
	}
	d, err := time.ParseDuration(v)
	if err != nil {
		log.Fatalf("config: %s is not a valid duration: %v", key, err)
	}
	return d
}
