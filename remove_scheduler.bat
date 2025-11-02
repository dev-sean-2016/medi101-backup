@echo off
REM ====================================================================
REM Windows Task Scheduler Removal Script
REM - Remove registered backup task
REM ====================================================================

echo.
echo ========================================
echo Task Scheduler Removal
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

set TASK_NAME=Medi101Backup

REM Check if task exists
schtasks /query /tn %TASK_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Task "%TASK_NAME%" is not registered
    echo.
    pause
    exit /b 0
)

REM Delete task
echo Removing task: %TASK_NAME%
schtasks /delete /tn %TASK_NAME% /f

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Task removed
    echo ========================================
) else (
    echo.
    echo ========================================
    echo [ERROR] Task removal failed
    echo ========================================
)

echo.
pause
