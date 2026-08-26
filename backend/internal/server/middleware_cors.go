package server

import (
	"net/http"
	"strings"
)

// withCORS is only needed for browser clients (admin/, and eventually app/'s own web
// build) — native mobile requests never go through a browser's CORS enforcement, which is
// why nothing here existed until admin/'s first real cross-origin fetch surfaced it.
// Bearer-token auth (not cookies) means credentialed CORS isn't required, so a wildcard
// "*" in CORS_ALLOWED_ORIGINS is safe to use for local dev; production should set the
// real origin(s) explicitly.
func withCORS(allowedOrigins []string, next http.Handler) http.Handler {
	allowAll := false
	allowed := make(map[string]bool, len(allowedOrigins))
	for _, o := range allowedOrigins {
		o = strings.TrimSpace(o)
		if o == "*" {
			allowAll = true
			continue
		}
		if o != "" {
			allowed[o] = true
		}
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		switch {
		case allowAll:
			w.Header().Set("Access-Control-Allow-Origin", "*")
		case origin != "" && allowed[origin]:
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Vary", "Origin")
		}
		if origin != "" {
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		}

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}
