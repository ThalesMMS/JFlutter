# JFlutter Development Makefile

.PHONY: help install analyze format test clean build generate

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	flutter pub get
	cd packages/core_fa && flutter pub get
	cd packages/core_pda && flutter pub get
	cd packages/core_tm && flutter pub get
	cd packages/core_regex && flutter pub get
	cd packages/conversions && flutter pub get
	cd packages/serializers && flutter pub get
	cd packages/viz && flutter pub get
	cd packages/playground && flutter pub get

analyze: ## Run static analysis
	flutter analyze

format: ## Format code
	flutter format .

test: ## Run tests
	flutter test

clean: ## Clean build artifacts
	flutter clean
	cd packages/core_fa && flutter clean
	cd packages/core_pda && flutter clean
	cd packages/core_tm && flutter clean
	cd packages/core_regex && flutter clean
	cd packages/conversions && flutter clean
	cd packages/serializers && flutter clean
	cd packages/viz && flutter clean
	cd packages/playground && flutter clean

build: ## Build the app
	flutter build apk --release

generate: ## Generate code (freezed, json_serializable)
	flutter packages pub run build_runner build --delete-conflicting-outputs

check: analyze format test ## Run all checks (analyze, format, test)
