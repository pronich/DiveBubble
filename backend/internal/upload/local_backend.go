package upload

import (
	"io"
	"os"
	"path/filepath"
)

// LocalBackend stores uploaded images on local disk — dev-only (see backend/.gitignore),
// and the fallback when Spaces isn't configured (see server.go).
type LocalBackend struct {
	BaseDir       string
	PublicBaseURL string
}

func NewLocalBackend(baseDir, publicBaseURL string) *LocalBackend {
	return &LocalBackend{BaseDir: baseDir, PublicBaseURL: publicBaseURL}
}

func (b *LocalBackend) store(category, name, _ string, data io.Reader) (string, error) {
	dir := filepath.Join(b.BaseDir, category)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return "", err
	}

	dst, err := os.Create(filepath.Join(dir, name))
	if err != nil {
		return "", err
	}
	defer dst.Close()

	if _, err := io.Copy(dst, data); err != nil {
		return "", err
	}

	return b.PublicBaseURL + "/uploads/" + category + "/" + name, nil
}
