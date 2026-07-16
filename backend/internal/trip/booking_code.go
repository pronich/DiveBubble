package trip

import (
	"crypto/rand"
	"errors"

	"github.com/jackc/pgx/v5/pgconn"
)

// Excludes visually-ambiguous characters (0/O, 1/I) — this code gets read off a screen and
// typed back in by hand, so every character needs to be unambiguous at a glance.
const bookingCodeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const bookingCodeLength = 8

func generateBookingCode() string {
	b := make([]byte, bookingCodeLength)
	buf := make([]byte, bookingCodeLength)
	_, _ = rand.Read(buf)
	for i, v := range buf {
		b[i] = bookingCodeAlphabet[int(v)%len(bookingCodeAlphabet)]
	}
	return string(b)
}

// uniqueViolation checks for Postgres error code 23505 (unique_violation) — used to retry
// booking-code generation on the astronomically rare collision rather than failing the
// whole trip creation outright.
func uniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
