package main

import (
	"log"
	"net/http"

	"divebuddy_be/internal/config"
	"divebuddy_be/internal/server"
)

func main() {
	cfg := config.Load()
	srv := server.New(cfg)

	log.Printf("listening on :%s", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, srv); err != nil {
		log.Fatalf("server: %v", err)
	}
}
