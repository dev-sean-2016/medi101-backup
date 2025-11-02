@echo off
REM ====================================================================
REM Git Installation Check Script
REM - Check if Git is installed
REM - Provide installation guide if not installed
REM ====================================================================

echo.
echo ========================================
echo Git Installation Check
echo ========================================
echo.

REM Check Git installation
where git >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Git is already installed
    git --version
    goto :end
)

echo [WARNING] Git is not installed
echo.
echo Please download and install Git from:
echo https://git-scm.com/download/win
echo.
echo After installation, run this script again
echo.
pause
exit /b 1

:end
echo.
pause
