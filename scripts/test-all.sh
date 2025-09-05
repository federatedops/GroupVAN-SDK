#!/bin/bash

# Run all SDK tests (unified test runner)

set -e

SCRIPT_DIR="$(dirname "$0")"
FAILED_TESTS=()
PASSED_TESTS=()

echo "🚀 Running All SDK Tests"
echo "========================"
echo ""

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo "▶️  Starting $test_name tests..."
    echo ""
    
    if "$SCRIPT_DIR/$test_script"; then
        PASSED_TESTS+=("$test_name")
        echo ""
        echo "✅ $test_name tests PASSED"
    else
        FAILED_TESTS+=("$test_name")
        echo ""
        echo "❌ $test_name tests FAILED"
    fi
    
    echo ""
    echo "----------------------------------------"
    echo ""
}

# Check if specific language is requested
if [ $# -eq 1 ]; then
    case "$1" in
        "csharp"|"c#"|"dotnet"|".net")
            run_test "C#/.NET" "test-csharp.sh"
            ;;
        "nodejs"|"node"|"js"|"javascript")
            run_test "Node.js" "test-nodejs.sh"
            ;;
        "python"|"py")
            run_test "Python" "test-python.sh"
            ;;
        "php")
            run_test "PHP" "test-php.sh"
            ;;
        *)
            echo "❌ Unknown language: $1"
            echo "   Supported: csharp, nodejs, python, php"
            exit 1
            ;;
    esac
else
    # Run all tests
    run_test "C#/.NET" "test-csharp.sh"
    run_test "Node.js" "test-nodejs.sh"
    run_test "Python" "test-python.sh"
    run_test "PHP" "test-php.sh"
fi

# Print summary
echo "📊 TEST SUMMARY"
echo "==============="
echo ""

if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
    echo "✅ PASSED (${#PASSED_TESTS[@]}):"
    for test in "${PASSED_TESTS[@]}"; do
        echo "   • $test"
    done
    echo ""
fi

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo "❌ FAILED (${#FAILED_TESTS[@]}):"
    for test in "${FAILED_TESTS[@]}"; do
        echo "   • $test"
    done
    echo ""
    echo "💡 Check individual test output above for details"
    exit 1
else
    echo "🎉 All tests passed successfully!"
fi