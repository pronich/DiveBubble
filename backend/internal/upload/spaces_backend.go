package upload

import (
	"context"
	"io"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

// SpacesBackend stores uploaded images in a DigitalOcean Space — S3-compatible, so this
// just uses the AWS SDK against Spaces' own endpoint rather than a DO-specific client.
type SpacesBackend struct {
	client    *s3.Client
	bucket    string
	publicURL string // CDN endpoint if configured, else the direct Spaces URL — see NewSpacesBackend
}

// NewSpacesBackend — region is an opaque string to the SDK (Spaces doesn't have "real" AWS
// regions, e.g. "fra1"), endpoint is the region-level Spaces endpoint (e.g.
// https://fra1.digitaloceanspaces.com, no bucket in it — the SDK prepends the bucket as a
// subdomain, matching how Spaces expects virtual-hosted-style requests). publicURL is the
// CDN endpoint if the Space has one enabled (e.g.
// https://<bucket>.fra1.cdn.digitaloceanspaces.com), else the same direct
// https://<bucket>.<region>.digitaloceanspaces.com host — either way, no trailing slash.
func NewSpacesBackend(endpoint, region, bucket, accessKey, secretKey, publicURL string) *SpacesBackend {
	client := s3.New(s3.Options{
		Region:       region,
		BaseEndpoint: aws.String(endpoint),
		Credentials:  credentials.NewStaticCredentialsProvider(accessKey, secretKey, ""),
	})
	return &SpacesBackend{client: client, bucket: bucket, publicURL: publicURL}
}

func (b *SpacesBackend) store(category, name, contentType string, data io.Reader) (string, error) {
	key := category + "/" + name
	_, err := b.client.PutObject(context.Background(), &s3.PutObjectInput{
		Bucket:      aws.String(b.bucket),
		Key:         aws.String(key),
		Body:        data,
		ContentType: aws.String(contentType),
		ACL:         types.ObjectCannedACLPublicRead,
	})
	if err != nil {
		return "", err
	}
	return b.publicURL + "/" + key, nil
}
