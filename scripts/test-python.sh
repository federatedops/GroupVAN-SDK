#!/bin/bash

# Test Python server SDK (mirrors .github/workflows/python.yml)

set -e

echo "🔧 Testing Python Server SDK"
echo "============================"

# Check if python and pip are installed
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python is not installed"
    echo "   Download from: https://python.org/downloads/"
    exit 1
fi

# Use python3 if available, otherwise python
PYTHON_CMD="python3"
PIP_CMD="pip3"

if ! command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
    PIP_CMD="pip"
fi

# Show version
echo "📦 Python version: $($PYTHON_CMD --version)"
echo "📦 pip version: $($PIP_CMD --version)"

# Change to Python server SDK directory
cd "$(dirname "$0")/../server-sdks/python"

echo ""
echo "📦 Installing dependencies..."
$PYTHON_CMD -m pip install --upgrade pip
$PIP_CMD install -e .
$PIP_CMD install pytest pytest-cov flake8 black mypy types-requests

echo ""
echo "🔍 Running flake8 (critical errors)..."
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics

echo ""
echo "🔍 Running flake8 (all issues - warning only)..."
flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

echo ""
echo "🎨 Checking code formatting with black..."
if black --check .; then
    echo "✅ Code formatting is correct"
else
    echo "❌ Code formatting issues found"
    echo "💡 Run 'black .' to fix formatting"
    exit 1
fi

echo ""
echo "🔍 Running type checks with mypy..."
mypy . --ignore-missing-imports

echo ""
echo "🧪 Running tests with coverage..."
pytest --cov=. --cov-report=xml --cov-report=html

echo ""
echo "✅ Python server SDK tests completed successfully!"

# Display coverage info
if [ -f "coverage.xml" ]; then
    echo ""
    echo "📊 Coverage report: coverage.xml"
fi
if [ -d "htmlcov" ]; then
    echo "📊 HTML coverage report: htmlcov/index.html"
    echo "   View with: python -m http.server 8000 (then open http://localhost:8000/htmlcov/)"
fi