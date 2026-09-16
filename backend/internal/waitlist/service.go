package waitlist

import (
	"context"
	"errors"
	"regexp"
	"strings"
)

var ErrInvalidEmail = errors.New("invalid email")

// Deliberately permissive: a real invalid address just means the notification email never reaches anyone, not a security problem.
var emailPattern = regexp.MustCompile(`^[^@\s]+@[^@\s]+\.[^@\s]+$`)

type Service struct {
	Repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{Repo: repo}
}

func (s *Service) Signup(ctx context.Context, email string) error {
	email = strings.TrimSpace(strings.ToLower(email))
	if !emailPattern.MatchString(email) {
		return ErrInvalidEmail
	}
	return s.Repo.Add(ctx, email)
}
