@echo off
REM Run all client tests (unified test runner for Windows)

setlocal enabledelayedexpansion

set PASSED_COUNT=0
set FAILED_COUNT=0
set PASSED_TESTS=
set FAILED_TESTS=

echo 🚀 Running All Client Tests
echo ============================
echo.

REM Function to run a test and track results (using subroutine)
goto :main

:run_test
set test_name=%~1
set test_script=%~2

echo ▶️  Starting %test_name% tests...
echo.

call "%~dp0%test_script%"
if errorlevel 1 (
    set /a FAILED_COUNT+=1
    if "%FAILED_TESTS%"=="" (
        set FAILED_TESTS=%test_name%
    ) else (
        set FAILED_TESTS=%FAILED_TESTS%, %test_name%
    )
    echo.
    echo ❌ %test_name% tests FAILED
) else (
    set /a PASSED_COUNT+=1
    if "%PASSED_TESTS%"=="" (
        set PASSED_TESTS=%test_name%
    ) else (
        set PASSED_TESTS=%PASSED_TESTS%, %test_name%
    )
    echo.
    echo ✅ %test_name% tests PASSED
)

echo.
echo ----------------------------------------
echo.
goto :eof

:main
REM Check if specific language is requested
if "%1"=="" goto :run_all

if /i "%1"=="csharp" goto :run_csharp
if /i "%1"=="c#" goto :run_csharp
if /i "%1"=="dotnet" goto :run_csharp
if /i "%1"==".net" goto :run_csharp

if /i "%1"=="nodejs" goto :run_nodejs
if /i "%1"=="node" goto :run_nodejs
if /i "%1"=="js" goto :run_nodejs
if /i "%1"=="javascript" goto :run_nodejs

if /i "%1"=="python" goto :run_python
if /i "%1"=="py" goto :run_python

if /i "%1"=="php" goto :run_php

echo ❌ Unknown language: %1
echo    Supported: csharp, nodejs, python, php
exit /b 1

:run_csharp
call :run_test "C#/.NET" "test-csharp.cmd"
goto :summary

:run_nodejs
call :run_test "Node.js" "test-nodejs.cmd"
goto :summary

:run_python
call :run_test "Python" "test-python.cmd"
goto :summary

:run_php
call :run_test "PHP" "test-php.cmd"
goto :summary

:run_all
REM Run all tests
call :run_test "C#/.NET" "test-csharp.cmd"
call :run_test "Node.js" "test-nodejs.cmd"
call :run_test "Python" "test-python.cmd"
call :run_test "PHP" "test-php.cmd"

:summary
REM Print summary
echo 📊 TEST SUMMARY
echo ===============
echo.

if %PASSED_COUNT% gtr 0 (
    echo ✅ PASSED (%PASSED_COUNT%):
    echo    %PASSED_TESTS%
    echo.
)

if %FAILED_COUNT% gtr 0 (
    echo ❌ FAILED (%FAILED_COUNT%):
    echo    %FAILED_TESTS%
    echo.
    echo 💡 Check individual test output above for details
    exit /b 1
) else (
    echo 🎉 All tests passed successfully!
)

endlocal