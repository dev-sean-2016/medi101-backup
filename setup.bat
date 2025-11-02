@echo off
REM ====================================================================
REM Medi101 Backup Program - One-Click Setup
REM 
REM This script automatically:
REM 1. Checks and installs Git
REM 2. Clones backup program repository
REM 3. Creates config file
REM 4. Registers Windows Task Scheduler
REM 
REM Usage:
REM   Right-click -> "Run as administrator"
REM ====================================================================

echo.
echo ========================================
echo Medi101 Backup Setup
echo ========================================
echo.

REM Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Administrator privileges required
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [1/5] Administrator check - OK
echo.

REM ====================================================================
REM Step 2: Check and install Git
REM ====================================================================
echo ----------------------------------------
echo [2/5] Git installation check
echo ----------------------------------------

where git >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Git is already installed
    git --version
    goto :git_ok
)

echo [INFO] Git not found. Installing automatically...
echo.

REM Method 1: Try winget (Windows 10/11)
echo [Trying] Installing Git via winget...
winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Git installed via winget
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    where git >nul 2>nul
    if %errorlevel% equ 0 (
        echo [OK] Git installation successful
        git --version
        goto :git_ok
    )
)

REM Method 2: Download and install via PowerShell
echo [Trying] Downloading Git installer...
echo (About 50MB, may take 1-2 minutes...)

set TEMP_INSTALLER=%TEMP%\Git-Installer.exe

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $tag = (Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest').tag_name; $version = $tag -replace 'v',''; $url = \"https://github.com/git-for-windows/git/releases/download/$tag/Git-$version-64-bit.exe\"; Write-Host \"Downloading...\"; Invoke-WebRequest -Uri $url -OutFile '%TEMP_INSTALLER%' -UseBasicParsing; exit 0 } catch { Write-Host \"Failed: $_\"; exit 1 } }"

if %errorlevel% neq 0 (
    echo [ERROR] Git download failed
    echo.
    echo Manual installation required:
    echo   https://git-scm.com/download/win
    pause
    exit /b 1
)

echo [OK] Download complete
echo Installing Git... (1-2 minutes, please wait...)

"%TEMP_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP-

timeout /t 5 /nobreak >nul
if exist "%TEMP_INSTALLER%" del /f /q "%TEMP_INSTALLER%"

set "PATH=%PATH%;C:\Program Files\Git\cmd"

where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git installed but not working
    echo Please restart computer and run this script again
    pause
    exit /b 1
)

:git_ok
echo.

REM ====================================================================
REM Step 3: Choose installation directory
REM ====================================================================
echo ----------------------------------------
echo [3/5] Installation directory
echo ----------------------------------------
echo.
echo Choose installation directory
echo Default: C:\medi101-backup
echo.
set /p INSTALL_PATH="Enter path (or press Enter for default): "

if "%INSTALL_PATH%"=="" (
    set INSTALL_PATH=C:\medi101-backup
)

echo.
echo Installation path: %INSTALL_PATH%
echo.

REM Check if directory exists
if exist "%INSTALL_PATH%" (
    echo [WARNING] Directory already exists
    echo.
    dir /b "%INSTALL_PATH%"
    echo.
    echo Delete existing folder and reinstall? (Y/N)
    set /p DELETE_EXISTING="Input: "
    
    if /i "%DELETE_EXISTING%"=="Y" (
        echo Deleting existing folder...
        rmdir /s /q "%INSTALL_PATH%"
    ) else (
        echo Installation cancelled
        pause
        exit /b 0
    )
)

echo.

REM ====================================================================
REM Step 4: Clone repository
REM ====================================================================
echo ----------------------------------------
echo [4/5] Downloading backup program
echo ----------------------------------------
echo.
echo Cloning from GitHub...
echo Repository: https://github.com/dev-sean-2016/medi101-backup.git
echo.

git clone https://github.com/dev-sean-2016/medi101-backup.git "%INSTALL_PATH%"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Git clone failed
    echo.
    echo Possible causes:
    echo   1. Internet connection problem
    echo   2. Repository access denied
    echo   3. Invalid repository URL
    echo.
    pause
    exit /b 1
)

echo [OK] Download complete
echo.

cd /d "%INSTALL_PATH%"

REM ====================================================================
REM Step 5: Create config file
REM ====================================================================
echo ----------------------------------------
echo [5/5] Config file setup
echo ----------------------------------------
echo.

if exist "config.json" (
    echo [OK] config.json already exists
    goto :config_ok
)

if exist "config.json.template" (
    copy config.json.template config.json >nul
    echo [OK] config.json created
    echo.
    echo [IMPORTANT] You must edit config.json!
    echo.
    echo Required fields:
    echo   - access_key: Kakao Cloud Access Key
    echo   - secret_key: Kakao Cloud Secret Key
    echo   - business_number: Your business number
    echo   - service_name: Service name (default: YSR2000)
    echo   - source_paths: Backup source path (default: C:\backup\WEEKLY)
    echo   - schedule_time: Execution time (default: 07:00)
    echo.
    echo Open config.json now? (Y/N)
    set /p OPEN_CONFIG="Input: "
    
    if /i "%OPEN_CONFIG%"=="Y" (
        notepad config.json
    )
) else (
    echo [WARNING] config.json.template not found
    echo Please create config.json manually
)

:config_ok
echo.

REM ====================================================================
REM Step 6: Check backup.exe
REM ====================================================================
echo ----------------------------------------
echo [Additional] Checking backup.exe
echo ----------------------------------------
echo.

if exist "backup.exe" (
    echo [OK] backup.exe exists
) else (
    echo [WARNING] backup.exe not found
    echo.
    echo backup.exe is required for backup execution
    echo Please ensure backup.exe is committed to the repository
    echo.
    echo Developer: Run build_exe.bat and commit backup.exe
    echo.
    pause
    exit /b 1
)

echo.

REM ====================================================================
REM Step 7: Register Task Scheduler
REM ====================================================================
echo ----------------------------------------
echo [Final] Task Scheduler registration
echo ----------------------------------------
echo.
echo Register daily automatic backup
echo.

set TASK_NAME=Medi101Backup
set SCHEDULE_TIME=07:00

if exist "config.json" (
    echo Reading schedule time from config.json...
    for /f "tokens=2 delims=:, " %%a in ('findstr /i "schedule_time" config.json') do (
        set SCHEDULE_TIME=%%a
    )
    set SCHEDULE_TIME=%SCHEDULE_TIME:"=%
)

echo Execution time: Daily at %SCHEDULE_TIME%
echo.

REM Delete existing task
schtasks /query /tn %TASK_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo Removing existing task...
    schtasks /delete /tn %TASK_NAME% /f >nul
)

REM Register new task
schtasks /create ^
    /tn "%TASK_NAME%" ^
    /tr "\"%INSTALL_PATH%\update_and_run.bat\" auto" ^
    /sc daily ^
    /st %SCHEDULE_TIME% ^
    /ru SYSTEM ^
    /rl HIGHEST ^
    /f >nul

if %errorlevel% equ 0 (
    echo [OK] Task Scheduler registration complete!
) else (
    echo [ERROR] Task Scheduler registration failed
    pause
    exit /b 1
)

echo.

REM ====================================================================
REM Installation complete
REM ====================================================================
echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo Installation info:
echo   - Path: %INSTALL_PATH%
echo   - Task: %TASK_NAME%
echo   - Schedule: Daily at %SCHEDULE_TIME%
echo.
echo Next steps:
echo   1. Edit config.json (REQUIRED)
echo      notepad %INSTALL_PATH%\config.json
echo.
echo   2. Manual test run
echo      %INSTALL_PATH%\update_and_run.bat
echo.
echo   3. Check logs
echo      notepad %INSTALL_PATH%\backup.log
echo.
echo Task Scheduler commands:
echo   - Check: schtasks /query /tn "%TASK_NAME%"
echo   - Run manually: schtasks /run /tn "%TASK_NAME%"
echo   - Remove: schtasks /delete /tn "%TASK_NAME%" /f
echo.
echo Edit config.json now? (Y/N)
set /p EDIT_NOW="Input: "

if /i "%EDIT_NOW%"=="Y" (
    notepad "%INSTALL_PATH%\config.json"
)

echo.
echo Thank you!
echo.
pause
