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

// Chat attachments get their own constant/map/error set, wider than avatar/trip-photo uploads, so the existing image-only call sites are untouched by this feature.
var ErrInvalidAttachment = errors.New("file must be a JPEG, PNG, WebP image, PDF, or MP4 video")
var ErrAttachmentTooLarge = errors.New("file exceeds the size limit")

const MaxAttachmentSize = 10 << 20 // 10MB — images, PDFs
// MaxVideoAttachmentSize is headroom to reject something pathological, not a target: the app already compresses video to ~720p client-side before upload.
const MaxVideoAttachmentSize = 50 << 20 // 50MB

var allowedAttachmentExtensions = map[string]string{
	"image/jpeg":      ".jpg",
	"image/png":       ".png",
	"image/webp":      ".webp",
	"application/pdf": ".pdf",
	"video/mp4":       ".mp4",
}

// Backend is where validated file bytes actually get stored; Service.Save's callers never see which implementation is in play, only the URL that comes back.
type Backend interface {
	store(category, name, contentType string, data io.Reader) (url string, err error)
}

type Service struct {
	backend Backend
}

func NewService(backend Backend) *Service {
	return &Service{backend: backend}
}

// Save sniffs the real content-type from the bytes rather than trusting the client-supplied header, which costs nothing to spoof.
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

// SaveAttachment returns the sniffed content-type alongside the URL so callers can derive "image"/"video"/"pdf" without re-sniffing the file themselves.
func (s *Service) SaveAttachment(category string, file multipart.File, header *multipart.FileHeader) (url, contentType string, err error) {
	// Cheapest reject first, before reading anything; this is only the upper bound of the two caps, checked precisely below once the type is sniffed.
	if header.Size > MaxVideoAttachmentSize {
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
	maxSize := int64(MaxAttachmentSize)
	if contentType == "video/mp4" {
		maxSize = MaxVideoAttachmentSize
	}
	if header.Size > maxSize {
		return "", "", ErrAttachmentTooLarge
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		return "", "", err
	}

	name := uuid.New().String() + ext
	url, err = s.backend.store(category, name, contentType, file)
	return url, contentType, err
}
