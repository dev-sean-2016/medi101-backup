@echo off
REM ====================================================================
REM Backup Program - Update and Run
REM - Git pull to get latest backup.exe
REM - Run backup.exe (Python not required)
REM ====================================================================

echo.
echo ========================================
echo Backup Program Starting
echo Time: %date% %time%
echo ========================================
echo.

REM Navigate to script directory
cd /d "%~dp0"

REM Check Git installation
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git not installed
    echo Please run install_git.bat first
    echo.
    pause
    exit /b 1
)

REM Check Git repository
if not exist ".git" (
    echo [WARNING] This folder is not a Git repository
    echo Please initialize or clone the repository
    echo.
    echo Example:
    echo   git init
    echo   git remote add origin [repository URL]
    echo   git pull origin main
    echo.
    pause
    exit /b 1
)

REM Update code
echo.
echo ----------------------------------------
echo [1/2] Git Pull - Downloading latest backup.exe
echo ----------------------------------------
git pull
if %errorlevel% neq 0 (
    echo [WARNING] Git pull failed. Check internet connection
    echo Continuing with existing backup.exe...
)

REM Check backup.exe
if not exist "backup.exe" (
    echo.
    echo [ERROR] backup.exe not found
    echo.
    echo Request from developer:
    echo   1. Run build_exe.bat to create backup.exe
    echo   2. Commit backup.exe to Git
    echo.
    pause
    exit /b 1
)

REM Check config.json
if not exist "config.json" (
    echo.
    echo [ERROR] config.json not found
    echo.
    echo Setup instructions:
    echo   1. Copy config.json.template to config.json
    echo   2. Edit config.json with actual values
    echo      - Access Key, Secret Key
    echo      - Business number
    echo      - Source paths
    echo.
    pause
    exit /b 1
)

REM Run backup
echo.
echo ----------------------------------------
echo [2/2] Running Backup
echo ----------------------------------------
backup.exe

REM Check result
if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Backup Complete!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo [ERROR] Backup failed
    echo Check backup.log for details
    echo ========================================
)

echo.
REM Auto-close when run by Task Scheduler
REM Pause only for manual execution
if "%1" neq "auto" (
    pause
)
