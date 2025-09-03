@echo off
REM Test C#/.NET client (mirrors .github/workflows/csharp.yml)

setlocal enabledelayedexpansion

echo 🔧 Testing C#/.NET Client
echo ==========================

REM Check if dotnet is installed
dotnet --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: .NET SDK is not installed
    echo    Download from: https://dotnet.microsoft.com/download
    exit /b 1
)

REM Show available SDKs
echo 📦 Available .NET SDKs:
dotnet --list-sdks

REM Determine target framework (default to net8.0)
if "%TARGET_FRAMEWORK%"=="" set TARGET_FRAMEWORK=net8.0
echo 🎯 Target Framework: %TARGET_FRAMEWORK%

REM Change to C# client directory
cd /d "%~dp0..\clients\csharp"

echo.
echo 📦 Restoring dependencies...
dotnet restore GroupVAN.sln
if errorlevel 1 (
    echo ❌ Failed to restore dependencies
    exit /b 1
)

echo.
echo 🔨 Building solution...
dotnet build GroupVAN.sln --no-restore --configuration Release -f %TARGET_FRAMEWORK%
if errorlevel 1 (
    echo ❌ Build failed
    exit /b 1
)

echo.
echo 🎨 Checking code formatting...
dotnet format GroupVAN.sln --verify-no-changes --no-restore
if errorlevel 1 (
    echo ❌ Code formatting issues found
    echo 💡 Run 'dotnet format GroupVAN.sln' to fix formatting
    exit /b 1
)

echo.
echo 🧪 Running tests with coverage...
dotnet test GroupVAN.sln --no-build --configuration Release --verbosity normal --collect:"XPlat Code Coverage" -f %TARGET_FRAMEWORK%
if errorlevel 1 (
    echo ❌ Tests failed
    exit /b 1
)

echo.
echo ✅ C#/.NET tests completed successfully!

REM Find and display coverage files
echo.
echo 📊 Coverage reports generated:
for /r %%f in (coverage.cobertura.xml) do echo    %%f

endlocal