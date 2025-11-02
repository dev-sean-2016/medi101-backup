@echo off
REM ====================================================================
REM Medi101 Backup Program - Build and Deploy Script (For Developers)
REM 
REM Prerequisites:
REM - Git installed
REM - Python 3.8+ installed
REM 
REM This script automatically:
REM 1. Checks Git and Python
REM 2. Clones or updates repository
REM 3. Installs Python packages
REM 4. Builds backup.exe
REM 5. Commits and pushes to Git
REM 
REM Usage:
REM   Double-click to run
REM ====================================================================

echo.
echo ========================================
echo Medi101 Backup - Build and Deploy
echo ========================================
echo.

REM ====================================================================
REM Step 1: Check Git
REM ====================================================================
echo ----------------------------------------
echo [1/5] Checking prerequisites
echo ----------------------------------------

where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git not installed
    echo.
    echo Please install Git first:
    echo   https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

echo [OK] Git found: 
git --version

REM Check Python (try python3 first, then python)
set PYTHON_CMD=
where python3 >nul 2>nul
if %errorlevel% equ 0 (
    set PYTHON_CMD=python3
    goto :python_found
)

where python >nul 2>nul
if %errorlevel% equ 0 (
    set PYTHON_CMD=python
    goto :python_found
)

REM Python not found - try to install
echo [INFO] Python not found. Installing automatically...
echo.

REM Try winget first
echo [Trying] Installing Python via winget...
winget install --id Python.Python.3.12 -e --source winget --silent --accept-package-agreements --accept-source-agreements >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Python installed via winget
    echo Refreshing PATH...
    set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312"
    set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312\Scripts"
    
    REM Check again
    where python >nul 2>nul
    if %errorlevel% equ 0 (
        set PYTHON_CMD=python
        echo [OK] Python installation successful
        python --version
        goto :python_found
    )
)

REM Try PowerShell download
echo [Trying] Downloading Python installer...
echo (About 25MB, 1-2 minutes...)
echo.

set TEMP_INSTALLER=%TEMP%\python-installer.exe

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ProgressPreference = 'SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $url = 'https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe'; Write-Host 'Downloading Python 3.12.7...'; Invoke-WebRequest -Uri $url -OutFile '%TEMP_INSTALLER%' -UseBasicParsing -TimeoutSec 300; if (Test-Path '%TEMP_INSTALLER%') { Write-Host 'Download complete'; exit 0 } else { exit 1 } } catch { Write-Host \"Download failed: $($_.Exception.Message)\"; exit 1 } }"

if %errorlevel% neq 0 (
    echo [ERROR] Automatic installation failed
    echo.
    echo RECOMMENDED: Manual installation
    echo   1. Visit: https://www.python.org/downloads/
    echo   2. Download Python 3.8 or later
    echo   3. During installation: CHECK "Add Python to PATH"
    echo   4. Run this script again
    echo.
    echo Open browser? (Y/N)
    set /p OPEN_PY="Input: "
    if /i "%OPEN_PY%"=="Y" start https://www.python.org/downloads/
    pause
    exit /b 1
)

echo [OK] Download complete
echo Installing Python... (Add to PATH automatically)

REM Install with options: /quiet (silent), InstallAllUsers=0 (current user), PrependPath=1 (add to PATH)
"%TEMP_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1

echo Waiting for installation to complete...
timeout /t 10 /nobreak >nul

if exist "%TEMP_INSTALLER%" del /f /q "%TEMP_INSTALLER%"

REM Refresh PATH
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312"
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312\Scripts"

REM Check installation
where python >nul 2>nul
if %errorlevel% equ 0 (
    set PYTHON_CMD=python
    echo [OK] Python installation successful
    python --version
    goto :python_found
)

where python3 >nul 2>nul
if %errorlevel% equ 0 (
    set PYTHON_CMD=python3
    echo [OK] Python installation successful
    python3 --version
    goto :python_found
)

echo [ERROR] Python installed but not found in PATH
echo Please restart your computer and run this script again
pause
exit /b 1

:python_found
echo [OK] Python found: 
%PYTHON_CMD% --version
echo.

REM ====================================================================
REM Step 2: Setup working directory
REM ====================================================================
echo ----------------------------------------
echo [2/5] Working directory setup
echo ----------------------------------------
echo.

set WORK_DIR=%USERPROFILE%\medi101-dev
echo Working directory: %WORK_DIR%
echo.

REM Update if exists, clone if not
if exist "%WORK_DIR%\.git" (
    echo [OK] Updating existing repository
    cd /d "%WORK_DIR%"
    
    echo Running git pull...
    git pull
    
    if %errorlevel% neq 0 (
        echo [WARNING] git pull failed. Continuing anyway...
    )
    
    goto :repo_ok
)

REM Clone repository
echo Cloning repository...
echo URL: https://github.com/dev-sean-2016/medi101-backup.git
echo.

git clone https://github.com/dev-sean-2016/medi101-backup.git "%WORK_DIR%"

if %errorlevel% neq 0 (
    echo [ERROR] Git clone failed
    echo Check internet connection and repository access
    pause
    exit /b 1
)

cd /d "%WORK_DIR%"

:repo_ok
echo [OK] Repository ready
echo.

REM ====================================================================
REM Step 3: Install Python packages
REM ====================================================================
echo ----------------------------------------
echo [3/5] Installing Python packages
echo ----------------------------------------
echo.

if not exist "requirements.txt" (
    echo [ERROR] requirements.txt not found
    pause
    exit /b 1
)

echo Upgrading pip...
%PYTHON_CMD% -m pip install --quiet --upgrade pip

echo Installing required packages...
%PYTHON_CMD% -m pip install --quiet -r requirements.txt

if %errorlevel% neq 0 (
    echo [ERROR] Package installation failed
    pause
    exit /b 1
)

echo [OK] Package installation complete
echo.

REM ====================================================================
REM Step 4: Build backup.exe
REM ====================================================================
echo ----------------------------------------
echo [4/5] Building backup.exe
echo ----------------------------------------
echo.

REM Clean previous build
if exist "build" (
    echo Cleaning old build...
    rmdir /s /q build
)
if exist "dist" (
    rmdir /s /q dist
)
if exist "backup.spec" (
    del /q backup.spec
)

echo Building with PyInstaller...
echo (This may take 1-2 minutes, please wait...)
echo.

pyinstaller --onefile ^
    --name=backup ^
    --console ^
    --clean ^
    backup.py

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Build failed
    echo Check backup.py for errors
    pause
    exit /b 1
)

REM Copy to project root
if exist "dist\backup.exe" (
    echo.
    echo Copying backup.exe to project root...
    copy /Y "dist\backup.exe" "backup.exe" >nul
    
    if %errorlevel% equ 0 (
        echo [OK] Copy complete
    )
)

REM Check file size
if exist "backup.exe" (
    for %%A in ("backup.exe") do set SIZE=%%~zA
    set /A SIZE_MB=%SIZE% / 1048576
    echo [OK] backup.exe created successfully (Size: %SIZE_MB% MB)
) else (
    echo [ERROR] backup.exe not created
    pause
    exit /b 1
)

echo.

REM ====================================================================
REM Step 5: Git commit and push
REM ====================================================================
echo ----------------------------------------
echo [5/5] Committing and pushing to GitHub
echo ----------------------------------------
echo.

REM Check for changes
git status --short

echo.
echo Adding backup.exe to Git...
git add backup.exe

REM Check if there are changes to commit
git diff --cached --quiet
if %errorlevel% equ 0 (
    echo [INFO] No changes detected. Skipping commit.
    goto :done
)

REM Get commit message
echo.
echo Enter commit message (or press Enter for default)
set /p COMMIT_MSG="Commit message: "

if "%COMMIT_MSG%"=="" (
    set COMMIT_MSG=Update backup.exe
)

echo.
echo Committing...
git commit -m "%COMMIT_MSG%"

if %errorlevel% neq 0 (
    echo [ERROR] Commit failed
    pause
    exit /b 1
)

echo [OK] Commit successful

echo.
echo Pushing to GitHub...
git push origin main

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Push failed
    echo.
    echo Possible causes:
    echo   1. Internet connection problem
    echo   2. Git authentication required (GitHub login)
    echo   3. Permission denied
    echo.
    echo To push manually:
    echo   cd %WORK_DIR%
    echo   git push origin main
    echo.
    pause
    exit /b 1
)

echo [OK] Push successful

:done
echo.
echo ========================================
echo Build and Deploy Complete!
echo ========================================
echo.
echo Summary:
echo   ✓ Git and Python verified
echo   ✓ Repository updated
echo   ✓ Packages installed
echo   ✓ backup.exe built (%SIZE_MB% MB)
echo   ✓ Changes committed and pushed
echo.
echo Output file: %WORK_DIR%\backup.exe
echo.
echo GitHub: https://github.com/dev-sean-2016/medi101-backup
echo.
echo Next step:
echo   Production servers will automatically download
echo   the latest backup.exe on next scheduled run.
echo.

REM Clean build folders
echo Clean temporary build folders? (Y/N)
set /p CLEANUP="Input: "

if /i "%CLEANUP%"=="Y" (
    if exist "build" rmdir /s /q build
    if exist "dist" rmdir /s /q dist
    if exist "backup.spec" del /q backup.spec
    echo [OK] Temporary folders cleaned
)

echo.
echo All done! You can close this window.
pause
