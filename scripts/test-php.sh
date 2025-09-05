#!/bin/bash

# Test PHP server SDK (mirrors .github/workflows/php.yml)

set -e

echo "🔧 Testing PHP Server SDK"
echo "========================="

# Check if php and composer are installed
if ! command -v php &> /dev/null; then
    echo "❌ Error: PHP is not installed"
    echo "   Download from: https://www.php.net/downloads"
    exit 1
fi

if ! command -v composer &> /dev/null; then
    echo "❌ Error: Composer is not installed"
    echo "   Download from: https://getcomposer.org/"
    exit 1
fi

# Show versions
echo "📦 PHP version: $(php --version | head -n1)"
echo "📦 Composer version: $(composer --version)"

# Change to PHP server SDK directory
cd "$(dirname "$0")/../server-sdks/php"

echo ""
echo "📦 Validating composer.json..."
composer validate --strict

echo ""
echo "📦 Installing dependencies..."
composer install --prefer-dist --no-progress

echo ""
echo "🎨 Running PHP CS Fixer (format check)..."
if vendor/bin/php-cs-fixer fix --config=.php-cs-fixer.php --dry-run --diff; then
    echo "✅ Code formatting is correct"
else
    echo "❌ Code formatting issues found"
    echo "💡 Run 'vendor/bin/php-cs-fixer fix --config=.php-cs-fixer.php' to fix"
    exit 1
fi

echo ""
echo "🔍 Running PHPStan (static analysis)..."
if [ -f "vendor/bin/phpstan" ]; then
    vendor/bin/phpstan analyse
else
    echo "⚠️  PHPStan not found, skipping static analysis"
fi

echo ""
echo "🧪 Running tests with coverage..."
vendor/bin/phpunit --coverage-clover coverage.xml

echo ""
echo "✅ PHP server SDK tests completed successfully!"

# Display coverage info
if [ -f "coverage.xml" ]; then
    echo ""
    echo "📊 Coverage report: coverage.xml"
fi