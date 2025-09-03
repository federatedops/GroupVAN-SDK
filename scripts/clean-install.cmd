@echo off
REM Clean and reinstall all dependencies

setlocal

echo 🧹 Cleaning and Reinstalling Dependencies
echo =========================================

set ROOT_DIR=%~dp0..

echo.
echo 🧹 Cleaning existing artifacts...

REM C#/.NET
echo   • Cleaning C# artifacts...
cd /d "%ROOT_DIR%\clients\csharp"
if exist bin rmdir /s /q bin
if exist obj rmdir /s /q obj
for /d /r %%d in (bin) do @if exist "%%d" rmdir /s /q "%%d"
for /d /r %%d in (obj) do @if exist "%%d" rmdir /s /q "%%d"
for /d /r %%d in (TestResults) do @if exist "%%d" rmdir /s /q "%%d"
cd /d "%ROOT_DIR%"

REM Node.js
echo   • Cleaning Node.js artifacts...
cd /d "%ROOT_DIR%\clients\nodejs"
if exist node_modules rmdir /s /q node_modules
if exist package-lock.json del package-lock.json
if exist coverage rmdir /s /q coverage
if exist .nyc_output rmdir /s /q .nyc_output
cd /d "%ROOT_DIR%"

REM Python
echo   • Cleaning Python artifacts...
cd /d "%ROOT_DIR%\clients\python"
if exist __pycache__ rmdir /s /q __pycache__
for /d /r %%d in (__pycache__) do @if exist "%%d" rmdir /s /q "%%d"
for /d /r %%d in (*.egg-info) do @if exist "%%d" rmdir /s /q "%%d"
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist .coverage del .coverage
if exist htmlcov rmdir /s /q htmlcov
if exist coverage.xml del coverage.xml
if exist .pytest_cache rmdir /s /q .pytest_cache
if exist .mypy_cache rmdir /s /q .mypy_cache
cd /d "%ROOT_DIR%"

REM PHP
echo   • Cleaning PHP artifacts...
cd /d "%ROOT_DIR%\clients\php"
if exist vendor rmdir /s /q vendor
if exist composer.lock del composer.lock
if exist coverage.xml del coverage.xml
if exist .php_cs.cache del .php_cs.cache
cd /d "%ROOT_DIR%"

echo.
echo 📦 Reinstalling dependencies...

REM C#/.NET
echo   • Installing C# dependencies...
cd /d "%ROOT_DIR%\clients\csharp"
dotnet restore GroupVAN.sln
if errorlevel 1 (
    echo ❌ Failed to install C# dependencies
    exit /b 1
)
cd /d "%ROOT_DIR%"

REM Node.js
echo   • Installing Node.js dependencies...
cd /d "%ROOT_DIR%\clients\nodejs"
npm install
if errorlevel 1 (
    echo ❌ Failed to install Node.js dependencies
    exit /b 1
)
cd /d "%ROOT_DIR%"

REM Python
echo   • Installing Python dependencies...
cd /d "%ROOT_DIR%\clients\python"
python -m pip install --upgrade pip
pip install -e .
pip install pytest pytest-cov flake8 black mypy types-requests
if errorlevel 1 (
    echo ❌ Failed to install Python dependencies
    exit /b 1
)
cd /d "%ROOT_DIR%"

REM PHP
echo   • Installing PHP dependencies...
cd /d "%ROOT_DIR%\clients\php"
composer install --prefer-dist --no-progress
if errorlevel 1 (
    echo ❌ Failed to install PHP dependencies
    exit /b 1
)
cd /d "%ROOT_DIR%"

echo.
echo ✅ Clean installation completed successfully!
echo.
echo Next steps:
echo   • Run tests: scripts\test-all.cmd
echo   • Or use make: make test-all

endlocal