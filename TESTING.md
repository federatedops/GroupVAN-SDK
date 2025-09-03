# Local Testing Guide

This guide helps you run the same tests locally that run in our CI/CD pipeline. All commands and configurations mirror our GitHub Actions workflows to ensure consistency between local development and automated testing.

## Quick Start

### Run All Tests
```bash
# Unix/Linux/macOS
make test-all

# Or manually
./scripts/test-all.sh

# Windows
scripts\test-all.cmd
```

### Run Tests for Specific Language
```bash
# C#/.NET
make test-csharp
./scripts/test-csharp.sh

# Node.js
make test-nodejs
./scripts/test-nodejs.sh

# Python
make test-python
./scripts/test-python.sh

# PHP
make test-php
./scripts/test-php.sh
```

## Prerequisites

### System Requirements
- **Git** (for version control)
- **Docker** (optional, for consistent testing environments)

### Language-Specific Requirements

#### C#/.NET
- **.NET SDK 6.0, 7.0, and 8.0**: [Download from Microsoft](https://dotnet.microsoft.com/download)
- **Verify installation**:
  ```bash
  dotnet --list-sdks
  # Should show 6.x.x, 7.x.x, and 8.x.x versions
  ```

#### Node.js
- **Node.js 16.x, 18.x, 20.x**: [Download from nodejs.org](https://nodejs.org/)
- **npm** (comes with Node.js)
- **Verify installation**:
  ```bash
  node --version
  npm --version
  ```

#### Python
- **Python 3.10, 3.11, 3.12, 3.13**: [Download from python.org](https://python.org/downloads/)
- **pip** (comes with Python)
- **Verify installation**:
  ```bash
  python --version  # or python3 --version
  pip --version     # or pip3 --version
  ```

#### PHP
- **PHP 8.1, 8.2, 8.3**: [Download from php.net](https://www.php.net/downloads)
- **Composer**: [Download from getcomposer.org](https://getcomposer.org/)
- **Extensions**: `mbstring`, `openssl`
- **Verify installation**:
  ```bash
  php --version
  composer --version
  ```

## Language-Specific Testing

### C#/.NET Testing

Our CI tests across .NET 6.0, 7.0, and 8.0. Locally, you can test with any installed version.

#### Commands (matching CI exactly)
```bash
cd clients/csharp

# Restore dependencies
dotnet restore GroupVAN.sln

# Build (specify target framework)
dotnet build GroupVAN.sln --no-restore --configuration Release -f net8.0

# Format check (must pass)
dotnet format GroupVAN.sln --verify-no-changes --no-restore

# Run tests with coverage
dotnet test GroupVAN.sln --no-build --configuration Release --verbosity normal --collect:"XPlat Code Coverage" -f net8.0
```

#### Target Frameworks
- `net6.0` - .NET 6
- `net7.0` - .NET 7  
- `net8.0` - .NET 8

#### Common Issues
- **Format check fails**: Run `dotnet format GroupVAN.sln` to fix formatting
- **Missing SDK**: Install the required .NET SDK version
- **Test failures**: Check that all dependencies are restored

### Node.js Testing

Our CI tests across Node.js 16.x, 18.x, and 20.x.

#### Commands (matching CI exactly)
```bash
cd clients/nodejs

# Install dependencies (exact versions from package-lock.json)
npm ci

# Run linter
npm run lint

# Run tests
npm test

# Generate coverage report
npm run coverage
```

#### Package Scripts
Check `package.json` for available scripts:
- `npm run lint` - ESLint checks
- `npm test` - Jest test runner
- `npm run coverage` - Coverage report generation

#### Common Issues
- **Lint failures**: Run `npm run lint -- --fix` to auto-fix issues
- **Node version mismatch**: Use nvm/nvm-windows to switch versions
- **Dependencies outdated**: Delete `node_modules` and run `npm ci`

### Python Testing

Our CI tests across Python 3.10, 3.11, 3.12, and 3.13.

#### Commands (matching CI exactly)
```bash
cd clients/python

# Install package in development mode
python -m pip install --upgrade pip
pip install -e .
pip install pytest pytest-cov flake8 black mypy types-requests

# Lint with flake8 (critical errors)
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics

# Lint with flake8 (all issues, warning only)
flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

# Format check with black (must pass)
black --check .

# Type check with mypy
mypy . --ignore-missing-imports

# Run tests with coverage
pytest --cov=. --cov-report=xml --cov-report=html
```

#### Common Issues
- **Format check fails**: Run `black .` to fix formatting
- **Import errors**: Ensure package is installed with `pip install -e .`
- **Type check failures**: Add type annotations or use `# type: ignore`

### PHP Testing

Our CI tests across PHP 8.1, 8.2, and 8.3.

#### Commands (matching CI exactly)
```bash
cd clients/php

# Validate composer.json
composer validate --strict

# Install dependencies
composer install --prefer-dist --no-progress

# Run PHP CS Fixer (format check)
vendor/bin/php-cs-fixer fix --config=.php-cs-fixer.php --dry-run --diff

# Run PHPStan (static analysis)
vendor/bin/phpstan analyse

# Run tests with coverage
vendor/bin/phpunit --coverage-clover coverage.xml
```

#### Common Issues
- **CS Fixer failures**: Run `vendor/bin/php-cs-fixer fix --config=.php-cs-fixer.php` to fix
- **PHPStan errors**: Fix type annotations and code issues
- **Missing extensions**: Install required PHP extensions

## Docker-Based Testing

For consistent environments across different machines:

### Build Test Environment
```bash
# Build multi-language test environment
docker build -f scripts/Dockerfile.testing -t groupvan-test .

# Run all tests in container
docker run --rm -v $(pwd):/app groupvan-test ./scripts/test-all.sh
```

### Language-Specific Containers
```bash
# Test specific language in isolation
docker run --rm -v $(pwd):/app -w /app/clients/csharp mcr.microsoft.com/dotnet/sdk:8.0 \
  bash -c "dotnet restore && dotnet test"
```

## IDE Integration

### Visual Studio Code
Recommended extensions for each language:
- **C#**: C# Dev Kit
- **Node.js**: ESLint, Prettier
- **Python**: Python, Black Formatter, Pylance
- **PHP**: PHP Intelephense

### Settings
Copy `.vscode/settings.json.template` to `.vscode/settings.json` for language-specific configurations.

## Continuous Integration Parity

### Matrix Testing
Our CI tests multiple versions of each runtime. To test locally across versions:

```bash
# Using version managers
nvm use 16 && npm test  # Node.js
nvm use 18 && npm test
nvm use 20 && npm test

pyenv local 3.10 && pytest  # Python
pyenv local 3.11 && pytest
pyenv local 3.12 && pytest
```

### Environment Variables
Some tests may require environment variables that CI sets:
- `TARGET_FRAMEWORK` - .NET target framework
- `NODE_ENV=test` - Node.js environment
- `CI=true` - CI environment flag

## Coverage Reports

### Local Coverage
Each language generates coverage reports:
- **C#**: `clients/csharp/**/TestResults/**/coverage.cobertura.xml`
- **Node.js**: `clients/nodejs/coverage/lcov.info`
- **Python**: `clients/python/coverage.xml`
- **PHP**: `clients/php/coverage.xml`

### Viewing Reports
```bash
# Python HTML report
cd clients/python && python -m http.server 8000
# Open http://localhost:8000/htmlcov/

# Node.js HTML report
cd clients/nodejs && npm run coverage:html
# Open coverage/lcov-report/index.html
```

## Troubleshooting

### Common Issues

#### "Command not found"
- Ensure all required tools are installed and in PATH
- Restart terminal after installing tools
- On Windows, use Command Prompt or PowerShell, not Git Bash for some tools

#### Permission Errors (Unix/Linux/macOS)
```bash
chmod +x scripts/*.sh
```

#### Tests Pass Locally But Fail in CI
- Check that you're using the same tool versions as CI
- Verify environment variables match CI settings
- Ensure file permissions are correct (executable scripts)

#### Dependency Conflicts
```bash
# Clear dependency caches
rm -rf clients/nodejs/node_modules clients/nodejs/package-lock.json
rm -rf clients/python/__pycache__ clients/python/*.egg-info
rm -rf clients/php/vendor clients/php/composer.lock
rm -rf clients/csharp/bin clients/csharp/obj

# Reinstall fresh
./scripts/clean-install.sh
```

### Getting Help

1. **Check CI logs**: Compare local output with GitHub Actions logs
2. **Verify tool versions**: Ensure they match CI matrix versions
3. **Clean installation**: Try fresh dependency installation
4. **Platform differences**: Some tools behave differently on Windows vs Unix

## Contributing

When adding new tests or modifying existing ones:

1. **Update CI first**: Modify `.github/workflows/*.yml` files
2. **Update local scripts**: Ensure `scripts/` match CI commands
3. **Update documentation**: Keep this guide in sync with changes
4. **Test locally**: Verify changes work across all supported platforms

## Scripts Reference

All testing scripts are in the `scripts/` directory:
- `test-all.sh` / `test-all.cmd` - Run all tests
- `test-csharp.sh` / `test-csharp.cmd` - C# tests
- `test-nodejs.sh` / `test-nodejs.cmd` - Node.js tests  
- `test-python.sh` / `test-python.cmd` - Python tests
- `test-php.sh` / `test-php.cmd` - PHP tests
- `clean-install.sh` / `clean-install.cmd` - Clean and reinstall dependencies