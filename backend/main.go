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
	"divebubble_be/internal/server"
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
