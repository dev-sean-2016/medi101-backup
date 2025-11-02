@echo off
REM ====================================================================
REM Medi101 Backup - Simple Setup (Git must be installed first)
REM 
REM Prerequisites: Git installed
REM Download Git: https://git-scm.com/download/win
REM ====================================================================

echo.
echo ========================================
echo Medi101 Backup - Simple Setup
echo ========================================
echo.

REM Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Administrator privileges required
    echo Right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Check Git installation
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git not installed
    echo.
    echo Please install Git first:
    echo   1. Visit: https://git-scm.com/download/win
    echo   2. Download and install Git
    echo   3. Run this script again
    echo.
    echo Open browser? (Y/N)
    set /p OPEN="Input: "
    if /i "%OPEN%"=="Y" start https://git-scm.com/download/win
    pause
    exit /b 1
)

echo [OK] Git found: 
git --version
echo.

REM Installation path
set INSTALL_PATH=C:\medi101-backup
echo Installation path: %INSTALL_PATH%
echo.

REM Clone repository
if exist "%INSTALL_PATH%" (
    echo [WARNING] Directory already exists
    echo Delete and reinstall? (Y/N)
    set /p DELETE="Input: "
    if /i "%DELETE%"=="Y" (
        rmdir /s /q "%INSTALL_PATH%"
    ) else (
        echo Cancelled
        pause
        exit /b 0
    )
)

echo Cloning repository...
git clone https://github.com/dev-sean-2016/medi101-backup.git "%INSTALL_PATH%"

if %errorlevel% neq 0 (
    echo [ERROR] Clone failed
    pause
    exit /b 1
)

cd /d "%INSTALL_PATH%"

REM Create config.json
if not exist "config.json" (
    if exist "config.json.template" (
        copy config.json.template config.json >nul
        echo [OK] config.json created
    )
)

REM Check backup.exe
if not exist "backup.exe" (
    echo [WARNING] backup.exe not found in repository
    echo Developer: Please run build_and_deploy.bat
    pause
    exit /b 1
)

REM Register Task Scheduler
echo.
echo Registering Task Scheduler...
set TASK_NAME=Medi101Backup
set SCHEDULE_TIME=07:00

schtasks /create ^
    /tn "%TASK_NAME%" ^
    /tr "\"%INSTALL_PATH%\update_and_run.bat\" auto" ^
    /sc daily ^
    /st %SCHEDULE_TIME% ^
    /ru SYSTEM ^
    /rl HIGHEST ^
    /f >nul

if %errorlevel% equ 0 (
    echo [OK] Task registered: Daily at %SCHEDULE_TIME%
) else (
    echo [ERROR] Task registration failed
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo IMPORTANT: Edit config.json with your settings
echo   Path: %INSTALL_PATH%\config.json
echo.
echo Required fields:
echo   - access_key
echo   - secret_key  
echo   - business_number
echo   - source_paths
echo.
echo Open config.json now? (Y/N)
set /p EDIT="Input: "
if /i "%EDIT%"=="Y" notepad "%INSTALL_PATH%\config.json"

echo.
echo Test run: %INSTALL_PATH%\update_and_run.bat
pause

