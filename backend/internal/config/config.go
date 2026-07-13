package config

import (
	"log"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	Port                  string
	DatabaseURL           string
	CentrifugoURL         string
	CentrifugoAPIKey      string
	CentrifugoTokenSecret string
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

	return Config{
		Port:                  port,
		DatabaseURL:           databaseURL,
		CentrifugoURL:         centrifugoURL,
		CentrifugoAPIKey:      centrifugoAPIKey,
		CentrifugoTokenSecret: centrifugoTokenSecret,
	}
}

func require(key string) string {
	v := os.Getenv(key)
	if strings.TrimSpace(v) == "" {
		log.Fatalf("config: %s is required", key)
	}
	return v
}
