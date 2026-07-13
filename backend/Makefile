.PHONY: dev dev-build dev-run dev-stop dev-logs compose-up compose-down compose-logs migrate-up migrate-down clean

dev:
	go run .

dev-build:
	mkdir -p ./bin
	go build -o ./bin/app .

dev-run: dev-build
	@mkdir -p ./bin
	@sh -c 'PORT="$${PORT:-8080}"; \
		./bin/app > ./bin/app.log 2>&1 & \
		echo $$! > ./bin/app.pid; \
		echo "started: pid=$$(cat ./bin/app.pid)"; \
		echo "api: http://localhost:$${PORT}"; \
		echo "health: http://localhost:$${PORT}/health"; \
		echo "logs: tail -f ./bin/app.log"; \
		echo "stop: make dev-stop"'

dev-stop:
	@sh -c 'if [ -f ./bin/app.pid ]; then \
		kill -TERM "$$(cat ./bin/app.pid)" 2>/dev/null || true; \
		rm -f ./bin/app.pid; \
		echo "stopped"; \
	else \
		echo "no pid file (./bin/app.pid)"; \
	fi'

dev-logs:
	@tail -f ./bin/app.log

compose-up:
	docker compose up -d
	@echo "postgres: 127.0.0.1:5433 (migrations applied automatically)"
	@echo "stop: make compose-down"

compose-down:
	docker compose down

compose-logs:
	docker compose logs -f --tail=200

# Requires golang-migrate CLI: brew install golang-migrate
# Loads DATABASE_URL from `.env` when present (same pattern as the app).
migrate-up:
	@set -a && [ -f .env ] && . ./.env && set +a; \
		test -n "$${DATABASE_URL}" || (echo "migrate-up: DATABASE_URL is not set (add it to .env)" && exit 1); \
		migrate -path migrations -database "$${DATABASE_URL}" up

migrate-down:
	@set -a && [ -f .env ] && . ./.env && set +a; \
		test -n "$${DATABASE_URL}" || (echo "migrate-down: DATABASE_URL is not set (add it to .env)" && exit 1); \
		migrate -path migrations -database "$${DATABASE_URL}" down 1

clean:
	rm -rf ./bin
