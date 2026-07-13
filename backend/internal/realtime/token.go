package realtime

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// TokenIssuer mints Centrifugo connection JWTs — clients use these to authenticate the WebSocket connection.
type TokenIssuer struct {
	secret string
}

func NewTokenIssuer(secret string) *TokenIssuer {
	return &TokenIssuer{secret: secret}
}

func (t *TokenIssuer) ConnectionToken(userID uuid.UUID) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID.String(),
		"exp": time.Now().Add(time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(t.secret))
}
