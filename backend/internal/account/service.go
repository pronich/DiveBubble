package account

import (
	"context"
	"log"

	"github.com/google/uuid"
)

// AppleIdentityStore is the subset of auth.IdentityRepository this package depends on — kept
// as an interface so account doesn't need to import auth's concrete types, same
// dependency-inversion style trip.Service already uses for divecenter.Service.
type AppleIdentityStore interface {
	GetAppleRefreshToken(ctx context.Context, userID uuid.UUID) (token string, ok bool, err error)
}

// AppleRevoker is the subset of auth.AppleTokenClient this package depends on.
type AppleRevoker interface {
	Revoke(ctx context.Context, refreshToken string) error
}

type Service struct {
	Repo            *Repository
	AppleIdentities AppleIdentityStore
	AppleTokens     AppleRevoker
}

func NewService(repo *Repository, appleIdentities AppleIdentityStore, appleTokens AppleRevoker) *Service {
	return &Service{Repo: repo, AppleIdentities: appleIdentities, AppleTokens: appleTokens}
}

// DeleteAccount revokes the diver's Apple authorization first (App Store Review Guideline
// 5.1.1(v)) — must happen before Repo.DeleteAccount, which deletes the auth_identities row
// (and the refresh token with it) as part of its anonymization transaction. Revoke failures
// are logged, not propagated: Apple's availability must never block a diver from completing
// account deletion, same stance Repo.DeleteAccount's own doc comment already takes on its
// "known accepted gap".
func (s *Service) DeleteAccount(ctx context.Context, userID uuid.UUID) error {
	if token, ok, err := s.AppleIdentities.GetAppleRefreshToken(ctx, userID); err != nil {
		log.Printf("account: could not look up apple refresh token for %s: %v", userID, err)
	} else if ok {
		if err := s.AppleTokens.Revoke(ctx, token); err != nil {
			log.Printf("account: apple token revoke failed for %s: %v", userID, err)
		}
	}
	return s.Repo.DeleteAccount(ctx, userID)
}
