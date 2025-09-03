@echo off
REM Test PHP client (mirrors .github/workflows/php.yml)

setlocal enabledelayedexpansion

echo 🔧 Testing PHP Client
echo ====================

REM Check if php and composer are installed
php --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: PHP is not installed
    echo    Download from: https://www.php.net/downloads
    exit /b 1
)

composer --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Composer is not installed
    echo    Download from: https://getcomposer.org/
    exit /b 1
)

REM Show versions
for /f "tokens=*" %%i in ('php --version ^| findstr /r "^PHP"') do set PHP_VERSION=%%i
for /f "tokens=*" %%i in ('composer --version') do set COMPOSER_VERSION=%%i
echo 📦 PHP version: %PHP_VERSION%
echo 📦 Composer version: %COMPOSER_VERSION%

REM Change to PHP client directory
cd /d "%~dp0..\clients\php"

echo.
echo 📦 Validating composer.json...
composer validate --strict
if errorlevel 1 (
    echo ❌ composer.json validation failed
    exit /b 1
)

echo.
echo 📦 Installing dependencies...
composer install --prefer-dist --no-progress
if errorlevel 1 (
    echo ❌ Failed to install dependencies
    exit /b 1
)

echo.
echo 🎨 Running PHP CS Fixer (format check)...
vendor\bin\php-cs-fixer fix --config=.php-cs-fixer.php --dry-run --diff
if errorlevel 1 (
    echo ❌ Code formatting issues found
    echo 💡 Run 'vendor\bin\php-cs-fixer fix --config=.php-cs-fixer.php' to fix
    exit /b 1
)

echo.
echo 🔍 Running PHPStan (static analysis)...
if exist "vendor\bin\phpstan" (
    vendor\bin\phpstan analyse
    if errorlevel 1 (
        echo ❌ Static analysis failed
        exit /b 1
    )
) else (
    echo ⚠️  PHPStan not found, skipping static analysis
)

echo.
echo 🧪 Running tests with coverage...
vendor\bin\phpunit --coverage-clover coverage.xml
if errorlevel 1 (
    echo ❌ Tests failed
    exit /b 1
)

echo.
echo ✅ PHP tests completed successfully!

REM Display coverage info
if exist "coverage.xml" (
    echo.
    echo 📊 Coverage report: coverage.xml
)

endlocal