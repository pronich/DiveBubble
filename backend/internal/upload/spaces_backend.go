package upload

import (
	"context"
	"io"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

// SpacesBackend uses the AWS SDK against Spaces' own endpoint, since Spaces is S3-compatible and needs no DO-specific client.
type SpacesBackend struct {
	client    *s3.Client
	bucket    string
	publicURL string // CDN endpoint if configured, else the direct Spaces URL — see NewSpacesBackend
}

// NewSpacesBackend takes endpoint without a bucket in it, since the SDK prepends the bucket as a subdomain to match Spaces' virtual-hosted-style requests.
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
