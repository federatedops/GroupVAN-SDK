@echo off
REM Test Python client (mirrors .github/workflows/python.yml)

setlocal enabledelayedexpansion

echo 🔧 Testing Python Client
echo ========================

REM Check if python and pip are installed
set PYTHON_CMD=python
set PIP_CMD=pip

python --version >nul 2>&1
if errorlevel 1 (
    REM Try python3
    python3 --version >nul 2>&1
    if errorlevel 1 (
        echo ❌ Error: Python is not installed
        echo    Download from: https://python.org/downloads/
        exit /b 1
    ) else (
        set PYTHON_CMD=python3
        set PIP_CMD=pip3
    )
)

REM Show versions
for /f "tokens=*" %%i in ('%PYTHON_CMD% --version') do set PYTHON_VERSION=%%i
for /f "tokens=*" %%i in ('%PIP_CMD% --version') do set PIP_VERSION=%%i
echo 📦 Python version: %PYTHON_VERSION%
echo 📦 pip version: %PIP_VERSION%

REM Change to Python client directory
cd /d "%~dp0..\clients\python"

echo.
echo 📦 Installing dependencies...
%PYTHON_CMD% -m pip install --upgrade pip
%PIP_CMD% install -e .
%PIP_CMD% install pytest pytest-cov flake8 black mypy types-requests
if errorlevel 1 (
    echo ❌ Failed to install dependencies
    exit /b 1
)

echo.
echo 🔍 Running flake8 (critical errors)...
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
if errorlevel 1 (
    echo ❌ Critical linting errors found
    exit /b 1
)

echo.
echo 🔍 Running flake8 (all issues - warning only)...
flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

echo.
echo 🎨 Checking code formatting with black...
black --check .
if errorlevel 1 (
    echo ❌ Code formatting issues found
    echo 💡 Run 'black .' to fix formatting
    exit /b 1
)

echo.
echo 🔍 Running type checks with mypy...
mypy . --ignore-missing-imports
if errorlevel 1 (
    echo ❌ Type check failed
    exit /b 1
)

echo.
echo 🧪 Running tests with coverage...
pytest --cov=. --cov-report=xml --cov-report=html
if errorlevel 1 (
    echo ❌ Tests failed
    exit /b 1
)

echo.
echo ✅ Python tests completed successfully!

REM Display coverage info
if exist "coverage.xml" (
    echo.
    echo 📊 Coverage report: coverage.xml
)
if exist "htmlcov" (
    echo 📊 HTML coverage report: htmlcov\index.html
    echo    View with: python -m http.server 8000 (then open http://localhost:8000/htmlcov/)
)

endlocal