#!/bin/bash

# Test C#/.NET client (mirrors .github/workflows/csharp.yml)

set -e

echo "🔧 Testing C#/.NET Client"
echo "=========================="

# Check if dotnet is installed
if ! command -v dotnet &> /dev/null; then
    echo "❌ Error: .NET SDK is not installed"
    echo "   Download from: https://dotnet.microsoft.com/download"
    exit 1
fi

# Show available SDKs
echo "📦 Available .NET SDKs:"
dotnet --list-sdks

# Determine target framework (default to net8.0)
TARGET_FRAMEWORK=${TARGET_FRAMEWORK:-net8.0}
echo "🎯 Target Framework: $TARGET_FRAMEWORK"

# Change to C# client directory
cd "$(dirname "$0")/../clients/csharp"

echo ""
echo "📦 Restoring dependencies..."
dotnet restore GroupVAN.sln

echo ""
echo "🔨 Building solution..."
dotnet build GroupVAN.sln --no-restore --configuration Release -f $TARGET_FRAMEWORK

echo ""
echo "🎨 Checking code formatting..."
dotnet format GroupVAN.sln --verify-no-changes --no-restore

echo ""
echo "🧪 Running tests with coverage..."
dotnet test GroupVAN.sln --no-build --configuration Release --verbosity normal --collect:"XPlat Code Coverage" -f $TARGET_FRAMEWORK

echo ""
echo "✅ C#/.NET tests completed successfully!"

# Find and display coverage files
echo ""
echo "📊 Coverage reports generated:"
find . -name "coverage.cobertura.xml" -type f | head -5