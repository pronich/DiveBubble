package upload

import (
	"errors"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"

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

// Service stores uploaded images on local disk, one subfolder per category (avatars/
// trips/specialties) — dev-only storage, gitignored (see backend/.gitignore). Callers
// only ever see the returned URL, so swapping this for object storage (DigitalOcean
// Spaces, matching the deploy target) later doesn't touch anything upstream.
type Service struct {
	BaseDir       string
	PublicBaseURL string
}

func NewService(baseDir, publicBaseURL string) *Service {
	return &Service{BaseDir: baseDir, PublicBaseURL: publicBaseURL}
}

// Save validates and stores an uploaded image under BaseDir/category/, returning the
// full public URL to persist as the caller's photo/avatar field.
func (s *Service) Save(category string, file multipart.File, header *multipart.FileHeader) (string, error) {
	if header.Size > MaxFileSize {
		return "", ErrTooLarge
	}

	// Sniff the actual bytes rather than trusting the client-supplied Content-Type header,
	// which costs nothing to spoof.
	sniff := make([]byte, 512)
	n, err := file.Read(sniff)
	if err != nil && err != io.EOF {
		return "", err
	}
	ext, ok := allowedExtensions[http.DetectContentType(sniff[:n])]
	if !ok {
		return "", ErrInvalidImage
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		return "", err
	}

	dir := filepath.Join(s.BaseDir, category)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return "", err
	}

	name := uuid.New().String() + ext
	dst, err := os.Create(filepath.Join(dir, name))
	if err != nil {
		return "", err
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		return "", err
	}

	return s.PublicBaseURL + "/uploads/" + category + "/" + name, nil
}
