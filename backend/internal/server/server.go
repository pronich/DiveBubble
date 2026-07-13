package server

import (
	"database/sql"
	"net/http"

	"divebuddy_be/internal/config"
	"divebuddy_be/internal/message"
	"divebuddy_be/internal/trip"
	"divebuddy_be/internal/user"
)

func New(cfg config.Config, db *sql.DB) http.Handler {
	tripRepo := trip.NewRepository(db)
	tripSvc := trip.NewService(tripRepo)
	userSvc := user.NewService(user.NewRepository(db))
	messageSvc := message.NewService(message.NewRepository(db))

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", handleHealth)
	registerTripRoutes(mux, tripSvc, userSvc)
	registerMessageRoutes(mux, messageSvc, tripSvc, userSvc)
	return mux
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}
