package auth

import (
	"context"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const appleJWKSURL = "https://appleid.apple.com/auth/keys"
const appleIssuer = "https://appleid.apple.com"

// AppleIdentity is the subset of a verified Apple identity token's claims we care about.
// Email/EmailVerified only ever carry a value on the token itself if Apple chose to include
// them there — the more reliable source (and the only source for the user's name) is the
// out-of-band credential the client gets alongside the token, only on the *first*
// authorization ever — see handleAuthApple's own doc comment.
type AppleIdentity struct {
	Sub           string
	Email         string
	EmailVerified bool
}

type appleClaims struct {
	Email         any    `json:"email"`
	EmailVerified any    `json:"email_verified"` // Apple sends this as either a bool or the string "true"/"false"
	Nonce         string `json:"nonce"`
	jwt.RegisteredClaims
}

// AppleKeySet caches Apple's JWKS (its RS256 public keys, keyed by "kid") in memory, with a
// TTL — refreshed lazily rather than on a background timer. If a token references a kid we
// don't have cached, we force one refresh and retry before giving up, which tolerates Apple
// rotating its signing keys without needing a backend restart.
type AppleKeySet struct {
	mu         sync.Mutex
	keys       map[string]*rsa.PublicKey
	fetchedAt  time.Time
	ttl        time.Duration
	httpClient *http.Client
}

func NewAppleKeySet() *AppleKeySet {
	return &AppleKeySet{ttl: 6 * time.Hour, httpClient: &http.Client{Timeout: 10 * time.Second}}
}

type jwksResponse struct {
	Keys []struct {
		Kty string `json:"kty"`
		Kid string `json:"kid"`
		N   string `json:"n"`
		E   string `json:"e"`
	} `json:"keys"`
}

func (s *AppleKeySet) refresh(ctx context.Context) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, appleJWKSURL, nil)
	if err != nil {
		return err
	}
	res, err := s.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		return err
	}
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("apple jwks: unexpected status %d", res.StatusCode)
	}

	var parsed jwksResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return err
	}

	keys := make(map[string]*rsa.PublicKey, len(parsed.Keys))
	for _, k := range parsed.Keys {
		if k.Kty != "RSA" {
			continue
		}
		nBytes, err := base64.RawURLEncoding.DecodeString(k.N)
		if err != nil {
			continue
		}
		eBytes, err := base64.RawURLEncoding.DecodeString(k.E)
		if err != nil {
			continue
		}
		keys[k.Kid] = &rsa.PublicKey{
			N: new(big.Int).SetBytes(nBytes),
			E: int(new(big.Int).SetBytes(eBytes).Int64()),
		}
	}

	s.mu.Lock()
	s.keys = keys
	s.fetchedAt = time.Now()
	s.mu.Unlock()
	return nil
}

// key returns the cached key for kid, refreshing first if the cache is empty/stale, or once
// more (forced) if kid still isn't found — Apple can rotate keys between our refreshes.
func (s *AppleKeySet) key(ctx context.Context, kid string) (*rsa.PublicKey, error) {
	s.mu.Lock()
	stale := s.keys == nil || time.Since(s.fetchedAt) > s.ttl
	k, ok := s.keys[kid]
	s.mu.Unlock()
	if ok && !stale {
		return k, nil
	}

	if err := s.refresh(ctx); err != nil {
		if ok {
			return k, nil // stale cache beats a hard failure if the network hiccups
		}
		return nil, err
	}

	s.mu.Lock()
	k, ok = s.keys[kid]
	s.mu.Unlock()
	if !ok {
		return nil, fmt.Errorf("apple jwks: no key found for kid %q", kid)
	}
	return k, nil
}

// VerifyAppleIdentityToken validates signature, issuer, audience and expiry, then checks
// rawNonce against the token's own nonce claim. audience is the app's bundle id
// (APPLE_AUDIENCE, e.g. io.divebubble.app — the App ID, not a Services ID; DiveBubble has no
// web Sign in with Apple flow).
func (s *AppleKeySet) VerifyAppleIdentityToken(ctx context.Context, idTokenString, audience, rawNonce string) (AppleIdentity, error) {
	var claims appleClaims
	token, err := jwt.ParseWithClaims(idTokenString, &claims, func(t *jwt.Token) (any, error) {
		kid, _ := t.Header["kid"].(string)
		if kid == "" {
			return nil, errors.New("apple token missing kid")
		}
		return s.key(ctx, kid)
	}, jwt.WithValidMethods([]string{"RS256"}), jwt.WithIssuer(appleIssuer), jwt.WithAudience(audience), jwt.WithIssuedAt())
	if err != nil {
		return AppleIdentity{}, err
	}
	if !token.Valid {
		return AppleIdentity{}, errors.New("apple token invalid")
	}

	if err := verifyAppleNonce(rawNonce, claims.Nonce); err != nil {
		return AppleIdentity{}, err
	}

	sub := strings.TrimSpace(claims.Subject)
	if sub == "" {
		return AppleIdentity{}, errors.New("apple token missing subject")
	}

	identity := AppleIdentity{Sub: sub}
	if v, ok := claims.Email.(string); ok {
		identity.Email = v
	}
	switch v := claims.EmailVerified.(type) {
	case bool:
		identity.EmailVerified = v
	case string:
		identity.EmailVerified = v == "true"
	}
	return identity, nil
}

// verifyAppleNonce hashes rawNonce (client → backend) and compares it against tokenNonce
// (the nonce claim Apple embedded, which is the SHA-256 digest the client sent *Apple* — see
// the client's own nonce-generation comment). Accepts both hex and base64url encodings of the
// digest, tolerant of either convention on the client side.
func verifyAppleNonce(rawNonce, tokenNonce string) error {
	if rawNonce == "" || tokenNonce == "" {
		return errors.New("apple nonce missing")
	}
	h := sha256.Sum256([]byte(rawNonce))
	hex := fmt.Sprintf("%x", h[:])
	if strings.EqualFold(hex, tokenNonce) {
		return nil
	}
	b64url := base64.RawURLEncoding.EncodeToString(h[:])
	if b64url == tokenNonce {
		return nil
	}
	return errors.New("apple nonce mismatch")
}
