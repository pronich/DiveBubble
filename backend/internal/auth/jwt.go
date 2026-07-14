package auth

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// TokenIssuer signs and verifies HS256 access tokens.
type TokenIssuer struct {
	secret         []byte
	accessTokenTTL time.Duration
}

func NewTokenIssuer(secret string, accessTokenTTL time.Duration) (*TokenIssuer, error) {
	s := strings.TrimSpace(secret)
	if s == "" {
		return nil, errors.New("jwt secret is empty")
	}
	if accessTokenTTL <= 0 {
		return nil, errors.New("access token TTL must be positive")
	}
	return &TokenIssuer{secret: []byte(s), accessTokenTTL: accessTokenTTL}, nil
}

// accessClaims is the payload for backend-issued access tokens.
// Sid is the auth_sessions row id, so a refresh can revoke the exact session an access token came from.
type accessClaims struct {
	Sid string `json:"sid"`
	jwt.RegisteredClaims
}

// IssueAccessToken creates a signed JWT with subject = internal user id.
func (t *TokenIssuer) IssueAccessToken(userID, sessionID uuid.UUID) (token string, expiresAt time.Time, err error) {
	now := time.Now()
	expiresAt = now.Add(t.accessTokenTTL).UTC()
	claims := accessClaims{
		Sid: sessionID.String(),
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	s, err := tok.SignedString(t.secret)
	if err != nil {
		return "", time.Time{}, err
	}
	return s, expiresAt, nil
}

// ParseAccessToken validates the token and returns the internal user id and auth_sessions id.
func (t *TokenIssuer) ParseAccessToken(tokenString string) (userID, sessionID uuid.UUID, err error) {
	tok, err := jwt.ParseWithClaims(tokenString, &accessClaims{}, func(token *jwt.Token) (any, error) {
		if token.Method != jwt.SigningMethodHS256 {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return t.secret, nil
	})
	if err != nil || !tok.Valid {
		return uuid.Nil, uuid.Nil, err
	}
	claims, ok := tok.Claims.(*accessClaims)
	if !ok {
		return uuid.Nil, uuid.Nil, errors.New("invalid claims type")
	}
	uid, err := uuid.Parse(strings.TrimSpace(claims.Subject))
	if err != nil {
		return uuid.Nil, uuid.Nil, errors.New("invalid subject claim")
	}
	sid, err := uuid.Parse(strings.TrimSpace(claims.Sid))
	if err != nil {
		return uuid.Nil, uuid.Nil, errors.New("invalid sid claim")
	}
	return uid, sid, nil
}
