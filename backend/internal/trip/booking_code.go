package trip

import (
	"crypto/rand"
	"errors"

	"github.com/jackc/pgx/v5/pgconn"
)

// Excludes visually-ambiguous characters (0/O, 1/I), since this code gets read off a screen and typed back in by hand.
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

// uniqueViolation detects Postgres code 23505, used to retry booking-code generation on collision rather than failing trip creation outright.
func uniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
