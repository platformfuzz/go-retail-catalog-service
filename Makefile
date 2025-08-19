.PHONY: help install build test test-integration lint serve docker-build docker-run docker-test clean

# Default port configuration
PORT ?= 8080

help: ## Show this help message
	@echo "Go Retail Catalog Service - Development Commands"
	@echo "================================================"
	@echo "Default port: ${PORT}"
	@echo "Override with: make PORT=9090 docker-run"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install Go dependencies
	go mod download
	go mod tidy

build: ## Build the Go application
	go build -v -o bin/catalog-service main.go

test: ## Run Go tests
	go test -v ./...

test-integration: ## Run integration tests
	go test -v -tags=integration ./...

test-coverage: ## Run tests with coverage
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

lint: ## Run Go linting
	golangci-lint run

lint-fix: ## Run Go linting with auto-fix
	golangci-lint run --fix

fmt: ## Format Go code
	go fmt ./...
	goimports -w .

vet: ## Run Go vet
	go vet ./...

serve: ## Start development server
	go run main.go

docker-build: ## Build Docker image
	docker build -t retail-catalog-service:local .

docker-run: ## Run Docker container
	docker run -p ${PORT}:${PORT} -e PORT=${PORT} retail-catalog-service:local

docker-test: ## Test Docker container
	docker run -d --name test-container -e PORT=${PORT} retail-catalog-service:local
	sleep 10
	docker inspect test-container --format='{{.State.Health.Status}}'
	docker stop test-container
	docker rm test-container

docker-compose-up: ## Start services with Docker Compose
	PORT=${PORT} docker-compose up -d

docker-compose-down: ## Stop services with Docker Compose
	docker-compose down

docker-compose-logs: ## View Docker Compose logs
	docker-compose logs -f

clean: ## Clean build artifacts
	go clean
	rm -rf bin/
	rm -f coverage.out coverage.html
	docker system prune -f

dev-setup: ## Setup development environment
	@echo "Setting up Go development environment..."
	@echo "1. Install dependencies..."
	go mod download
	go mod tidy
	@echo "2. Build application..."
	go build -v -o bin/catalog-service main.go
	@echo "3. Run tests..."
	go test -v ./...
	@echo "4. Start development server..."
	@echo "Run 'make serve' to start the dev server"
	@echo "Run 'make docker-build' to build Docker image"
	@echo "Run 'make docker-compose-up' to start with Docker Compose"

# CI/CD specific targets
ci-build: ## Build for CI/CD
	go build -v -o bin/catalog-service main.go

ci-test: ## Run tests for CI/CD
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out

ci-lint: ## Run linting for CI/CD
	golangci-lint run --timeout=5m

ci-security: ## Run security checks
	govulncheck ./...

# Release targets
release-build: ## Build release binaries
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/catalog-service-linux-amd64 main.go
	GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o bin/catalog-service-darwin-amd64 main.go
	GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o bin/catalog-service-darwin-arm64 main.go

# Database targets
db-migrate: ## Run database migrations (if applicable)
	@echo "Database migration commands would go here"
	@echo "Example: go run cmd/migrate/main.go"

db-seed: ## Seed database with sample data (if applicable)
	@echo "Database seeding commands would go here"
	@echo "Example: go run cmd/seed/main.go"
