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
	AccessTokenTTL        time.Duration
	RefreshSessionTTL     time.Duration
	UploadDir             string
	PublicBaseURL         string
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
	accessTokenTTL := durationEnv("ACCESS_TOKEN_TTL", 8*time.Hour)
	refreshSessionTTL := durationEnv("REFRESH_SESSION_TTL", 180*24*time.Hour)

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

	return Config{
		Port:                  port,
		DatabaseURL:           databaseURL,
		CentrifugoURL:         centrifugoURL,
		CentrifugoAPIKey:      centrifugoAPIKey,
		CentrifugoTokenSecret: centrifugoTokenSecret,
		JWTSecret:             jwtSecret,
		GoogleServerClientID:  googleServerClientID,
		AccessTokenTTL:        accessTokenTTL,
		RefreshSessionTTL:     refreshSessionTTL,
		UploadDir:             uploadDir,
		PublicBaseURL:         publicBaseURL,
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
