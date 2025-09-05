#!/bin/bash

# Test Node.js server SDK (mirrors .github/workflows/nodejs.yml)

set -e

echo "🔧 Testing Node.js Server SDK"
echo "============================="

# Check if node and npm are installed
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js is not installed"
    echo "   Download from: https://nodejs.org/"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm is not installed"
    echo "   npm comes with Node.js"
    exit 1
fi

# Show versions
echo "📦 Node.js version: $(node --version)"
echo "📦 npm version: $(npm --version)"

# Change to Node.js server SDK directory
cd "$(dirname "$0")/../server-sdks/nodejs"

echo ""
echo "📦 Installing dependencies..."
npm ci

echo ""
echo "🔍 Running linter..."
if npm run lint --if-present; then
    echo "✅ Linting passed"
else
    echo "❌ Linting failed"
    echo "💡 Try running: npm run lint -- --fix"
    exit 1
fi

echo ""
echo "🧪 Running tests..."
npm test

echo ""
echo "📊 Generating coverage report..."
npm run coverage --if-present

echo ""
echo "✅ Node.js server SDK tests completed successfully!"

# Display coverage info if available
if [ -f "coverage/lcov.info" ]; then
    echo ""
    echo "📊 Coverage report: coverage/lcov.info"
    if [ -d "coverage/lcov-report" ]; then
        echo "📊 HTML report: coverage/lcov-report/index.html"
    fi
fi