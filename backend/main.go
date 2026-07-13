package main

import (
	"log"
	"net/http"

	"divebuddy_be/internal/config"
	"divebuddy_be/internal/db"
	"divebuddy_be/internal/server"
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

	log.Printf("listening on :%s", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, srv); err != nil {
		log.Fatalf("server: %v", err)
	}
}
