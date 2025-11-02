@echo off
REM ====================================================================
REM Windows Task Scheduler Registration Script
REM - Register backup program to run daily at specified time
REM ====================================================================

echo.
echo ========================================
echo Task Scheduler Registration
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

REM Current directory path
set CURRENT_DIR=%~dp0
set TASK_NAME=Medi101Backup

echo Task name: %TASK_NAME%
echo Script path: %CURRENT_DIR%update_and_run.bat
echo.

REM Set execution time (default: 07:00)
REM To change time, edit config.json or modify SCHEDULE_TIME below
set SCHEDULE_TIME=07:00

echo Execution time: Daily at %SCHEDULE_TIME%
echo.

REM Delete existing task (if exists)
schtasks /query /tn %TASK_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo Existing task found. Removing...
    schtasks /delete /tn %TASK_NAME% /f
)

REM Register task scheduler
echo.
echo Registering to Task Scheduler...
schtasks /create ^
    /tn "%TASK_NAME%" ^
    /tr "\"%CURRENT_DIR%update_and_run.bat\" auto" ^
    /sc daily ^
    /st %SCHEDULE_TIME% ^
    /ru SYSTEM ^
    /rl HIGHEST ^
    /f

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Task registered!
    echo ========================================
    echo.
    echo Task name: %TASK_NAME%
    echo Execution time: Daily at %SCHEDULE_TIME%
    echo.
    echo How to check:
    echo   1. Open "Task Scheduler" program
    echo   2. Search for "%TASK_NAME%" in "Task Scheduler Library"
    echo.
    echo Manual run:
    echo   schtasks /run /tn "%TASK_NAME%"
    echo.
) else (
    echo.
    echo ========================================
    echo [ERROR] Task registration failed
    echo ========================================
    echo.
)

pause
