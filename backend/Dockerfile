FROM golang:1.26-alpine AS builder

RUN apk add --no-cache ca-certificates

WORKDIR /src

COPY go.mod go.sum ./
COPY main.go ./
COPY internal ./internal

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
	go build -trimpath -ldflags="-s -w" -o /out/app .


FROM alpine:3.21

RUN apk add --no-cache ca-certificates wget \
	&& addgroup -g 65532 -S app \
	&& adduser -u 65532 -S -G app -H -s /sbin/nologin app

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /out/app /app

# /data/uploads is expected to be mounted as a volume in production (see docker-compose.prod.yml)
# — anything written directly into the image's own filesystem is lost on every redeploy.
RUN mkdir -p /data/uploads && chown -R app:app /app /data

USER app

EXPOSE 8080

HEALTHCHECK --interval=60s --timeout=5s --start-period=10s --retries=3 \
	CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/app"]
