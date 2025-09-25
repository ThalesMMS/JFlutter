# JFlutter Development Makefile

.PHONY: help install analyze format test clean build generate ci format-check

PACKAGE_DIRS := $(shell find packages -maxdepth 1 -mindepth 1 -type d 2>/dev/null)

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies for the root app and all local packages
        flutter pub get
        @for dir in $(PACKAGE_DIRS); do \
          if [ -f $$dir/pubspec.yaml ]; then \
            echo "==> flutter pub get ($$dir)"; \
            (cd $$dir && flutter pub get); \
          fi; \
        done

analyze: ## Run static analysis
	flutter analyze

format: ## Format code (writes changes)
        flutter format .

format-check: ## Verify formatting without writing changes
        flutter format --set-exit-if-changed .

test: ## Run tests
	flutter test

clean: ## Clean build artifacts
        flutter clean
        @for dir in $(PACKAGE_DIRS); do \
          if [ -f $$dir/pubspec.yaml ]; then \
            echo "==> flutter clean ($$dir)"; \
            (cd $$dir && flutter clean); \
          fi; \
        done

build: ## Build the app
	flutter build apk --release

generate: ## Generate code (freezed, json_serializable)
	flutter packages pub run build_runner build --delete-conflicting-outputs

check: analyze format-check test ## Run all checks (analyze, format, test)

ci: ## Run the full CI pipeline (install, format check, analyze, test)
        $(MAKE) install
        $(MAKE) format-check
        $(MAKE) analyze
        $(MAKE) test
