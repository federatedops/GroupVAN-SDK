#!/bin/bash

# Clean and reinstall all dependencies

set -e

echo "🧹 Cleaning and Reinstalling Dependencies"
echo "========================================="

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$SCRIPT_DIR/.."

echo ""
echo "🧹 Cleaning existing artifacts..."

# C#/.NET
echo "  • Cleaning C# artifacts..."
cd "$ROOT_DIR/clients/csharp"
rm -rf bin obj **/bin **/obj **/TestResults
cd "$ROOT_DIR"

# Node.js
echo "  • Cleaning Node.js artifacts..."
cd "$ROOT_DIR/clients/nodejs"
rm -rf node_modules package-lock.json coverage .nyc_output
cd "$ROOT_DIR"

# Python
echo "  • Cleaning Python artifacts..."
cd "$ROOT_DIR/clients/python"
rm -rf __pycache__ **/__pycache__ *.egg-info build dist .coverage htmlcov coverage.xml .pytest_cache .mypy_cache
cd "$ROOT_DIR"

# PHP
echo "  • Cleaning PHP artifacts..."
cd "$ROOT_DIR/clients/php"
rm -rf vendor composer.lock coverage.xml .php_cs.cache
cd "$ROOT_DIR"

echo ""
echo "📦 Reinstalling dependencies..."

# C#/.NET
echo "  • Installing C# dependencies..."
cd "$ROOT_DIR/clients/csharp"
dotnet restore GroupVAN.sln
cd "$ROOT_DIR"

# Node.js
echo "  • Installing Node.js dependencies..."
cd "$ROOT_DIR/clients/nodejs"
npm install
cd "$ROOT_DIR"

# Python
echo "  • Installing Python dependencies..."
cd "$ROOT_DIR/clients/python"
python3 -m pip install --upgrade pip 2>/dev/null || python -m pip install --upgrade pip
pip3 install -e . 2>/dev/null || pip install -e .
pip3 install pytest pytest-cov flake8 black mypy types-requests 2>/dev/null || pip install pytest pytest-cov flake8 black mypy types-requests
cd "$ROOT_DIR"

# PHP
echo "  • Installing PHP dependencies..."
cd "$ROOT_DIR/clients/php"
composer install --prefer-dist --no-progress
cd "$ROOT_DIR"

echo ""
echo "✅ Clean installation completed successfully!"
echo ""
echo "Next steps:"
echo "  • Run tests: ./scripts/test-all.sh"
echo "  • Or use make: make test-all"