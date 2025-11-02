@echo off
REM ====================================================================
REM Medi101 Backup Program - Build and Deploy Script (For Developers)
REM 
REM This script automatically:
REM 1. Checks and installs Git
REM 2. Checks Python installation
REM 3. Clones or updates repository
REM 4. Installs Python packages
REM 5. Builds backup.exe
REM 6. Commits and pushes to Git
REM 
REM Usage:
REM   Double-click to run (administrator recommended)
REM ====================================================================

echo.
echo ========================================
echo Medi101 Backup - Build and Deploy
echo ========================================
echo.

REM ====================================================================
REM Step 1: Check and install Git
REM ====================================================================
echo ----------------------------------------
echo [1/6] Git installation check
echo ----------------------------------------

where git >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Git is already installed
    git --version
    goto :git_ok
)

echo [INFO] Git not found. Installing automatically...
echo.

REM Try winget first
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

REM Try PowerShell download
echo [Trying] Downloading Git via PowerShell...
echo (About 50MB, 1-2 minutes...)

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

echo Installing Git...
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
REM Step 2: Check Python installation
REM ====================================================================
echo ----------------------------------------
echo [2/6] Python installation check
echo ----------------------------------------

where python >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Python is installed
    python --version
    goto :python_ok
)

echo [ERROR] Python not installed
echo.
echo Installation required:
echo   1. Visit https://www.python.org/downloads/
echo   2. Download Python 3.8 or later
echo   3. During installation, CHECK "Add Python to PATH"
echo   4. After installation, run this script again
echo.
echo Open browser? (Y/N)
set /p OPEN_PY="Input: "

if /i "%OPEN_PY%"=="Y" (
    start https://www.python.org/downloads/
)

pause
exit /b 1

:python_ok
echo.

REM ====================================================================
REM Step 3: Setup working directory
REM ====================================================================
echo ----------------------------------------
echo [3/6] Working directory setup
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
    pause
    exit /b 1
)

cd /d "%WORK_DIR%"

:repo_ok
echo [OK] Repository ready
echo.

REM ====================================================================
REM Step 4: Install Python packages
REM ====================================================================
echo ----------------------------------------
echo [4/6] Python package installation
echo ----------------------------------------
echo.

if not exist "requirements.txt" (
    echo [WARNING] requirements.txt not found
    goto :skip_install
)

echo Upgrading pip...
python -m pip install --quiet --upgrade pip

echo.
echo Installing packages...
python -m pip install --quiet -r requirements.txt

if %errorlevel% neq 0 (
    echo [ERROR] Package installation failed
    pause
    exit /b 1
)

echo [OK] Package installation complete
goto :packages_ok

:skip_install
echo [SKIP] Package installation skipped

:packages_ok
echo.

REM ====================================================================
REM Step 5: Build backup.exe
REM ====================================================================
echo ----------------------------------------
echo [5/6] Building backup.exe
echo ----------------------------------------
echo.

REM Clean previous build
if exist "build" rmdir /s /q build
if exist "dist" rmdir /s /q dist
if exist "backup.spec" del /q backup.spec

echo Building with PyInstaller...
echo (1-2 minutes, please wait...)
echo.

pyinstaller --onefile ^
    --name=backup ^
    --console ^
    --clean ^
    backup.py

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Build failed
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
    echo [OK] backup.exe created (Size: %SIZE_MB% MB)
) else (
    echo [ERROR] backup.exe not created
    pause
    exit /b 1
)

echo.

REM ====================================================================
REM Step 6: Git commit and push
REM ====================================================================
echo ----------------------------------------
echo [6/6] Git commit and push
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
    echo [INFO] No changes to commit. Skipping push.
    goto :done
)

REM Get commit message
echo.
echo Enter commit message
echo (Example: Update backup.exe, Bug fix, New feature, etc.)
echo.
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
    echo Manual push:
    echo   cd %WORK_DIR%
    echo   git push origin main
    echo.
    pause
    exit /b 1
)

:done
echo.
echo ========================================
echo Build and Deploy Complete!
echo ========================================
echo.
echo Summary:
echo   - Git: Checked/Installed
echo   - Python: Checked
echo   - Repository: Cloned/Updated
echo   - Packages: Installed
echo   - backup.exe: Built
echo   - Git: Committed and Pushed
echo.
echo Generated file:
echo   - %WORK_DIR%\backup.exe
echo.
echo GitHub repository:
echo   https://github.com/dev-sean-2016/medi101-backup
echo.
echo Next step:
echo   On production server, run setup.bat
echo   Latest backup.exe will be downloaded automatically
echo.

REM Clean build folders
echo.
echo Delete build and dist folders? (Y/N)
set /p CLEANUP="Input: "

if /i "%CLEANUP%"=="Y" (
    if exist "build" rmdir /s /q build
    if exist "dist" rmdir /s /q dist
    if exist "backup.spec" del /q backup.spec
    echo [OK] Temporary folders cleaned
)

echo.
echo Done!
pause
