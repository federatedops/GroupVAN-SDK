# GroupVAN SDK Testing Makefile
# Unified testing interface for all SDK languages

.PHONY: help test-all test-csharp test-nodejs test-python test-php clean install-deps

# Default target
help:
	@echo "GroupVAN SDK Testing"
	@echo "==================="
	@echo ""
	@echo "Available targets:"
	@echo "  test-all      - Run tests for all SDK languages"
	@echo "  test-csharp   - Run C#/.NET server SDK tests"
	@echo "  test-nodejs   - Run Node.js server SDK tests"
	@echo "  test-python   - Run Python server SDK tests"
	@echo "  test-php      - Run PHP server SDK tests"
	@echo ""
	@echo "Utility targets:"
	@echo "  install-deps  - Install all dependencies"
	@echo "  clean         - Clean all build artifacts and dependencies"
	@echo "  clean-csharp  - Clean C# build artifacts"
	@echo "  clean-nodejs  - Clean Node.js dependencies"
	@echo "  clean-python  - Clean Python build artifacts"
	@echo "  clean-php     - Clean PHP dependencies"
	@echo ""
	@echo "Coverage targets:"
	@echo "  coverage      - Generate coverage reports for all languages"
	@echo ""
	@echo "Examples:"
	@echo "  make test-all              # Test all languages"
	@echo "  make test-csharp           # Test only C#"
	@echo "  make clean install-deps    # Fresh installation"

# Test all languages
test-all:
	@echo "🚀 Running all SDK tests..."
	@./scripts/test-all.sh

# Individual language tests
test-csharp:
	@echo "🔧 Testing C#/.NET server SDK..."
	@./scripts/test-csharp.sh

test-nodejs:
	@echo "🔧 Testing Node.js server SDK..."
	@./scripts/test-nodejs.sh

test-python:
	@echo "🔧 Testing Python server SDK..."
	@./scripts/test-python.sh

test-php:
	@echo "🔧 Testing PHP server SDK..."
	@./scripts/test-php.sh

# Install dependencies for all languages
install-deps: install-csharp install-nodejs install-python install-php

install-csharp:
	@echo "📦 Installing C# dependencies..."
	@cd server-sdks/csharp && dotnet restore GroupVAN.sln

install-nodejs:
	@echo "📦 Installing Node.js dependencies..."
	@cd server-sdks/nodejs && npm ci

install-python:
	@echo "📦 Installing Python dependencies..."
	@cd server-sdks/python && pip install -e . && pip install pytest pytest-cov flake8 black mypy types-requests

install-php:
	@echo "📦 Installing PHP dependencies..."
	@cd server-sdks/php && composer install --prefer-dist --no-progress

# Clean build artifacts and dependencies
clean: clean-csharp clean-nodejs clean-python clean-php

clean-csharp:
	@echo "🧹 Cleaning C# artifacts..."
	@cd server-sdks/csharp && rm -rf bin obj **/**/bin **/**/obj **/**/TestResults

clean-nodejs:
	@echo "🧹 Cleaning Node.js artifacts..."
	@cd server-sdks/nodejs && rm -rf node_modules coverage .nyc_output

clean-python:
	@echo "🧹 Cleaning Python artifacts..."
	@cd server-sdks/python && rm -rf __pycache__ **/__pycache__ *.egg-info build dist .coverage htmlcov coverage.xml .pytest_cache .mypy_cache

clean-php:
	@echo "🧹 Cleaning PHP artifacts..."
	@cd server-sdks/php && rm -rf vendor coverage.xml .php_cs.cache

# Coverage reports
coverage: coverage-csharp coverage-nodejs coverage-python coverage-php

coverage-csharp:
	@echo "📊 Generating C# coverage..."
	@cd server-sdks/csharp && dotnet test --collect:"XPlat Code Coverage" --results-directory ./coverage

coverage-nodejs:
	@echo "📊 Generating Node.js coverage..."
	@cd server-sdks/nodejs && npm run coverage

coverage-python:
	@echo "📊 Generating Python coverage..."
	@cd server-sdks/python && pytest --cov=. --cov-report=html --cov-report=xml

coverage-php:
	@echo "📊 Generating PHP coverage..."
	@cd server-sdks/php && vendor/bin/phpunit --coverage-html coverage --coverage-clover coverage.xml

# Lint and format checks
lint: lint-csharp lint-nodejs lint-python lint-php

lint-csharp:
	@echo "🔍 Checking C# formatting..."
	@cd server-sdks/csharp && dotnet format GroupVAN.sln --verify-no-changes

lint-nodejs:
	@echo "🔍 Linting Node.js code..."
	@cd server-sdks/nodejs && npm run lint

lint-python:
	@echo "🔍 Linting Python code..."
	@cd server-sdks/python && flake8 . && black --check . && mypy . --ignore-missing-imports

lint-php:
	@echo "🔍 Linting PHP code..."
	@cd server-sdks/php && vendor/bin/php-cs-fixer fix --dry-run --diff

# Format code
format: format-csharp format-nodejs format-python format-php

format-csharp:
	@echo "🎨 Formatting C# code..."
	@cd server-sdks/csharp && dotnet format GroupVAN.sln

format-nodejs:
	@echo "🎨 Formatting Node.js code..."
	@cd server-sdks/nodejs && npm run lint -- --fix

format-python:
	@echo "🎨 Formatting Python code..."
	@cd server-sdks/python && black .

format-php:
	@echo "🎨 Formatting PHP code..."
	@cd server-sdks/php && vendor/bin/php-cs-fixer fix

# CI simulation (runs the same commands as GitHub Actions)
ci: ci-csharp ci-nodejs ci-python ci-php

ci-csharp:
	@echo "🤖 Running C# CI simulation..."
	@cd server-sdks/csharp && \
		dotnet restore GroupVAN.sln && \
		dotnet build GroupVAN.sln --no-restore --configuration Release && \
		dotnet format GroupVAN.sln --verify-no-changes --no-restore && \
		dotnet test GroupVAN.sln --no-build --configuration Release --verbosity normal --collect:"XPlat Code Coverage"

ci-nodejs:
	@echo "🤖 Running Node.js CI simulation..."
	@cd server-sdks/nodejs && \
		npm ci && \
		npm run lint && \
		npm test && \
		npm run coverage

ci-python:
	@echo "🤖 Running Python CI simulation..."
	@cd server-sdks/python && \
		pip install -e . && \
		pip install pytest pytest-cov flake8 black mypy types-requests && \
		flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics && \
		black --check . && \
		mypy . --ignore-missing-imports && \
		pytest --cov=. --cov-report=xml

ci-php:
	@echo "🤖 Running PHP CI simulation..."
	@cd server-sdks/php && \
		composer validate --strict && \
		composer install --prefer-dist --no-progress && \
		vendor/bin/php-cs-fixer fix --dry-run --diff && \
		vendor/bin/phpunit --coverage-clover coverage.xml

# Development helpers
dev-setup: clean install-deps
	@echo "🎯 Development environment ready!"

# Check tool versions
versions:
	@echo "Tool Versions:"
	@echo "=============="
	@echo -n ".NET SDK: " && dotnet --version 2>/dev/null || echo "Not installed"
	@echo -n "Node.js: " && node --version 2>/dev/null || echo "Not installed"
	@echo -n "npm: " && npm --version 2>/dev/null || echo "Not installed"
	@echo -n "Python: " && python --version 2>/dev/null || python3 --version 2>/dev/null || echo "Not installed"
	@echo -n "pip: " && pip --version 2>/dev/null || pip3 --version 2>/dev/null || echo "Not installed"
	@echo -n "PHP: " && php --version | head -n1 2>/dev/null || echo "Not installed"
	@echo -n "Composer: " && composer --version 2>/dev/null || echo "Not installed"