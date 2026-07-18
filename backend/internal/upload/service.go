package upload

import (
	"errors"
	"io"
	"mime/multipart"
	"net/http"

	"github.com/google/uuid"
)

var ErrInvalidImage = errors.New("file must be a JPEG, PNG, or WebP image")
var ErrTooLarge = errors.New("file exceeds the 5MB size limit")

const MaxFileSize = 5 << 20 // 5MB

var allowedExtensions = map[string]string{
	"image/jpeg": ".jpg",
	"image/png":  ".png",
	"image/webp": ".webp",
}

// Backend is where validated file bytes actually get stored — one subfolder ("category")
// per kind of upload (avatars/trips/specialties/...). LocalBackend (dev) and SpacesBackend
// (prod, DigitalOcean Spaces) are the two implementations; Service.Save's callers never see
// which one is in play, only the URL that comes back.
type Backend interface {
	store(category, name, contentType string, data io.Reader) (url string, err error)
}

type Service struct {
	backend Backend
}

func NewService(backend Backend) *Service {
	return &Service{backend: backend}
}

// Save validates an uploaded image (size cap, real content-type sniffed from the bytes
// rather than trusting the client-supplied header, which costs nothing to spoof) and hands
// it to the configured Backend, returning the full public URL to persist as the caller's
// photo/avatar field.
func (s *Service) Save(category string, file multipart.File, header *multipart.FileHeader) (string, error) {
	if header.Size > MaxFileSize {
		return "", ErrTooLarge
	}

	sniff := make([]byte, 512)
	n, err := file.Read(sniff)
	if err != nil && err != io.EOF {
		return "", err
	}
	contentType := http.DetectContentType(sniff[:n])
	ext, ok := allowedExtensions[contentType]
	if !ok {
		return "", ErrInvalidImage
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		return "", err
	}

	name := uuid.New().String() + ext
	return s.backend.store(category, name, contentType, file)
}
