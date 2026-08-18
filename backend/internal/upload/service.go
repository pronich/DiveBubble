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

// Chat attachments allow a wider (image + PDF) type list and a larger size cap than the
// avatar/trip-photo/etc. uploads above — kept as a separate constant/map/error set rather than
// parameterizing Save, so the 5 existing image-only call sites are untouched by this feature.
var ErrInvalidAttachment = errors.New("file must be a JPEG, PNG, WebP image or PDF")
var ErrAttachmentTooLarge = errors.New("file exceeds the 10MB size limit")

const MaxAttachmentSize = 10 << 20 // 10MB

var allowedAttachmentExtensions = map[string]string{
	"image/jpeg":      ".jpg",
	"image/png":       ".png",
	"image/webp":      ".webp",
	"application/pdf": ".pdf",
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

// SaveAttachment is Save's chat-attachment counterpart: same real-content-type sniffing, wider
// allow-list (image + PDF), larger size cap. Returns the sniffed content-type alongside the URL
// so callers can derive "image"/"pdf" without re-sniffing the file themselves.
func (s *Service) SaveAttachment(category string, file multipart.File, header *multipart.FileHeader) (url, contentType string, err error) {
	if header.Size > MaxAttachmentSize {
		return "", "", ErrAttachmentTooLarge
	}

	sniff := make([]byte, 512)
	n, err := file.Read(sniff)
	if err != nil && err != io.EOF {
		return "", "", err
	}
	contentType = http.DetectContentType(sniff[:n])
	ext, ok := allowedAttachmentExtensions[contentType]
	if !ok {
		return "", "", ErrInvalidAttachment
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		return "", "", err
	}

	name := uuid.New().String() + ext
	url, err = s.backend.store(category, name, contentType, file)
	return url, contentType, err
}
