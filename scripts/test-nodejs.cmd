@echo off
REM Test Node.js client (mirrors .github/workflows/nodejs.yml)

setlocal enabledelayedexpansion

echo 🔧 Testing Node.js Client
echo =========================

REM Check if node and npm are installed
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Node.js is not installed
    echo    Download from: https://nodejs.org/
    exit /b 1
)

npm --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: npm is not installed
    echo    npm comes with Node.js
    exit /b 1
)

REM Show versions
for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
echo 📦 Node.js version: %NODE_VERSION%
echo 📦 npm version: %NPM_VERSION%

REM Change to Node.js client directory
cd /d "%~dp0..\clients\nodejs"

echo.
echo 📦 Installing dependencies...
npm ci
if errorlevel 1 (
    echo ❌ Failed to install dependencies
    exit /b 1
)

echo.
echo 🔍 Running linter...
npm run lint --if-present
if errorlevel 1 (
    echo ❌ Linting failed
    echo 💡 Try running: npm run lint -- --fix
    exit /b 1
)

echo.
echo 🧪 Running tests...
npm test
if errorlevel 1 (
    echo ❌ Tests failed
    exit /b 1
)

echo.
echo 📊 Generating coverage report...
npm run coverage --if-present

echo.
echo ✅ Node.js tests completed successfully!

REM Display coverage info if available
if exist "coverage\lcov.info" (
    echo.
    echo 📊 Coverage report: coverage\lcov.info
    if exist "coverage\lcov-report" (
        echo 📊 HTML report: coverage\lcov-report\index.html
    )
)

endlocal