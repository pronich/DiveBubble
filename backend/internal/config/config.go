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
	// GoogleServerClientIDs holds every Web OAuth client id whose id_tokens we accept, briefly two during a credential migration until old app builds update.
	GoogleServerClientIDs []string
	// AppleAudience is the iOS app's bundle id (not a Services ID, since DiveBubble has no web Sign in with Apple flow), defaulting to the project's one bundle id so no env var is required in dev.
	AppleAudience string
	// AppleTeamID/AppleKeyID/ApplePrivateKey are optional and only needed to revoke Apple authorization on account deletion (Guideline 5.1.1(v)); empty disables just that side effect, never sign-in.
	AppleTeamID           string
	AppleKeyID            string
	ApplePrivateKey       string
	AccessTokenTTL        time.Duration
	RefreshSessionTTL     time.Duration
	SessionRetentionGrace time.Duration
	UploadDir             string
	PublicBaseURL         string
	CORSAllowedOrigins    []string

	// Passwordless email login (magic link for admin/, OTP for app/): ResendAPIKey empty disables real sending, and every other field here has a working dev default.
	ResendAPIKey      string
	EmailFromAddress  string
	EmailMagicLinkTTL time.Duration
	EmailOTPTTL       time.Duration
	EmailCodeCooldown time.Duration
	// AdminBaseURL is where a magic-link email points back to (admin/'s root, read via Uri.base query params — see MagicLinkGate), distinct from PublicBaseURL which is the backend's own base URL for uploaded files.
	AdminBaseURL string

	// FirebaseCredentialsJSON is the Firebase service account JSON content (not a file path); empty disables push entirely, the local dev default.
	FirebaseCredentialsJSON string

	// Spaces* are all optional; SpacesBucket empty means "use LocalBackend" (dev default), and they must be set together in production since there's no partial-Spaces mode.
	SpacesEndpoint  string
	SpacesRegion    string
	SpacesBucket    string
	SpacesAccessKey string
	SpacesSecretKey string
	// SpacesPublicURL is the CDN endpoint if enabled, else the direct digitaloceanspaces.com host, computed once here (no trailing slash) so callers never re-derive it.
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
	googleServerClientIDs := strings.Split(require("GOOGLE_SERVER_CLIENT_IDS"), ",")
	for i, id := range googleServerClientIDs {
		googleServerClientIDs[i] = strings.TrimSpace(id)
	}
	appleAudience := os.Getenv("APPLE_AUDIENCE")
	if appleAudience == "" {
		appleAudience = "io.divebubble.app"
	}
	appleTeamID := os.Getenv("APPLE_TEAM_ID")
	appleKeyID := os.Getenv("APPLE_KEY_ID")
	// Stored as a single-line env var with literal \n sequences, unescaped to real newlines here rather than relying on the dotenv parser's own quoting.
	applePrivateKey := strings.ReplaceAll(os.Getenv("APPLE_PRIVATE_KEY"), `\n`, "\n")
	accessTokenTTL := durationEnv("ACCESS_TOKEN_TTL", 8*time.Hour)
	refreshSessionTTL := durationEnv("REFRESH_SESSION_TTL", 180*24*time.Hour)
	// How long an expired/revoked auth_sessions row is kept before physical deletion, separate from RefreshSessionTTL which only governs token usability.
	sessionRetentionGrace := durationEnv("SESSION_RETENTION_GRACE", 30*24*time.Hour)

	uploadDir := os.Getenv("UPLOAD_DIR")
	if uploadDir == "" {
		uploadDir = "./uploads"
	}
	// What the client uses to build a full image URL from Save()'s relative path; must be reachable from the device/simulator, not just the server host.
	publicBaseURL := os.Getenv("PUBLIC_BASE_URL")
	if publicBaseURL == "" {
		publicBaseURL = "http://localhost:" + port
	}

	// "*" by default is safe since Bearer-token auth uses no cookies/credentials, and local dev's Flutter web port varies run to run; set explicitly in production.
	corsAllowedOrigins := []string{"*"}
	if raw := os.Getenv("CORS_ALLOWED_ORIGINS"); raw != "" {
		corsAllowedOrigins = strings.Split(raw, ",")
	}

	firebaseCredentialsJSON := os.Getenv("FIREBASE_CREDENTIALS_JSON")

	resendAPIKey := os.Getenv("RESEND_API_KEY")
	emailFromAddress := os.Getenv("EMAIL_FROM_ADDRESS")
	if emailFromAddress == "" {
		emailFromAddress = "DiveBubble <login@divebubble.io>"
	}
	emailMagicLinkTTL := durationEnv("EMAIL_MAGIC_LINK_TTL", 15*time.Minute)
	emailOTPTTL := durationEnv("EMAIL_OTP_TTL", 10*time.Minute)
	emailCodeCooldown := durationEnv("EMAIL_CODE_COOLDOWN", 30*time.Second)
	adminBaseURL := os.Getenv("ADMIN_BASE_URL")
	if adminBaseURL == "" {
		adminBaseURL = "http://localhost:5050"
	}

	spacesEndpoint := os.Getenv("SPACES_ENDPOINT")
	spacesRegion := os.Getenv("SPACES_REGION")
	spacesBucket := os.Getenv("SPACES_BUCKET")
	spacesAccessKey := os.Getenv("SPACES_ACCESS_KEY")
	spacesSecretKey := os.Getenv("SPACES_SECRET_KEY")
	spacesPublicURL := strings.TrimSuffix(os.Getenv("SPACES_CDN_URL"), "/")
	if spacesPublicURL == "" && spacesBucket != "" {
		// No CDN configured — fall back to the direct virtual-hosted-style Space URL derived from endpoint + bucket.
		spacesPublicURL = strings.Replace(spacesEndpoint, "https://", "https://"+spacesBucket+".", 1)
	}

	return Config{
		Port:                    port,
		DatabaseURL:             databaseURL,
		CentrifugoURL:           centrifugoURL,
		CentrifugoAPIKey:        centrifugoAPIKey,
		CentrifugoTokenSecret:   centrifugoTokenSecret,
		JWTSecret:               jwtSecret,
		GoogleServerClientIDs:   googleServerClientIDs,
		AppleAudience:           appleAudience,
		AppleTeamID:             appleTeamID,
		AppleKeyID:              appleKeyID,
		ApplePrivateKey:         applePrivateKey,
		AccessTokenTTL:          accessTokenTTL,
		RefreshSessionTTL:       refreshSessionTTL,
		SessionRetentionGrace:   sessionRetentionGrace,
		UploadDir:               uploadDir,
		PublicBaseURL:           publicBaseURL,
		CORSAllowedOrigins:      corsAllowedOrigins,
		FirebaseCredentialsJSON: firebaseCredentialsJSON,
		ResendAPIKey:            resendAPIKey,
		EmailFromAddress:        emailFromAddress,
		EmailMagicLinkTTL:       emailMagicLinkTTL,
		EmailOTPTTL:             emailOTPTTL,
		EmailCodeCooldown:       emailCodeCooldown,
		AdminBaseURL:            adminBaseURL,
		SpacesEndpoint:          spacesEndpoint,
		SpacesRegion:            spacesRegion,
		SpacesBucket:            spacesBucket,
		SpacesAccessKey:         spacesAccessKey,
		SpacesSecretKey:         spacesSecretKey,
		SpacesPublicURL:         spacesPublicURL,
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
