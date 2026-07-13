package server

import (
	"database/sql"
	"net/http"

	"divebuddy_be/internal/config"
	"divebuddy_be/internal/trip"
)

func New(cfg config.Config, db *sql.DB) http.Handler {
	tripRepo := trip.NewRepository(db)
	tripSvc := trip.NewService(tripRepo)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", handleHealth)
	registerTripRoutes(mux, tripSvc)
	return mux
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}
