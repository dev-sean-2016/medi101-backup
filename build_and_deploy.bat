@echo off
REM ====================================================================
REM Medi101 Backup - Build and Deploy (Simplified)
REM 
REM Prerequisites (install manually):
REM - Git: https://git-scm.com/download/win
REM - Python 3.8+: https://www.python.org/downloads/
REM 
REM This script: Clone → Build → Push
REM ====================================================================

echo.
echo ========================================
echo Medi101 Backup - Build and Deploy
echo ========================================
echo.

REM ====================================================================
REM Check prerequisites
REM ====================================================================
echo [1/5] Checking prerequisites...

where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git not installed
    echo Install from: https://git-scm.com/download/win
    pause
    exit /b 1
)
echo [OK] Git: 
git --version

REM Check Python
set PYTHON_CMD=
where python3 >nul 2>nul
if %errorlevel% equ 0 (
    set PYTHON_CMD=python3
) else (
    where python >nul 2>nul
    if %errorlevel% equ 0 (
        set PYTHON_CMD=python
    ) else (
        echo [ERROR] Python not installed
        echo Install from: https://www.python.org/downloads/
        pause
        exit /b 1
    )
)

echo [OK] Python: 
%PYTHON_CMD% --version
echo.

REM ====================================================================
REM Setup working directory
REM ====================================================================
echo [2/5] Setting up working directory...

set WORK_DIR=%USERPROFILE%\medi101-dev
echo Working directory: %WORK_DIR%
echo.

REM Update existing or clone new
if exist "%WORK_DIR%\.git" (
    echo Repository exists. Updating...
    cd /d "%WORK_DIR%"
    git pull
    if %errorlevel% neq 0 (
        echo [WARNING] git pull failed, continuing...
    )
) else (
    echo Cloning repository...
    git clone https://github.com/dev-sean-2016/medi101-backup.git "%WORK_DIR%"
    if %errorlevel% neq 0 (
        echo [ERROR] Clone failed
        pause
        exit /b 1
    )
    cd /d "%WORK_DIR%"
)

echo [OK] Repository ready
echo.

REM ====================================================================
REM Install packages
REM ====================================================================
echo [3/5] Installing Python packages...

if not exist "requirements.txt" (
    echo [ERROR] requirements.txt not found
    pause
    exit /b 1
)

echo Upgrading pip...
%PYTHON_CMD% -m pip install --quiet --upgrade pip

echo Installing packages...
%PYTHON_CMD% -m pip install --quiet -r requirements.txt

if %errorlevel% neq 0 (
    echo [ERROR] Package installation failed
    pause
    exit /b 1
)

echo [OK] Packages installed
echo.

REM ====================================================================
REM Build backup.exe
REM ====================================================================
echo [4/5] Building backup.exe...

REM Clean old builds
if exist "build" rmdir /s /q build
if exist "dist" rmdir /s /q dist
if exist "backup.spec" del /q backup.spec

echo Building... (1-2 minutes)
pyinstaller --onefile --name=backup --console --clean backup.py

if %errorlevel% neq 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)

REM Copy to root
if exist "dist\backup.exe" (
    copy /Y "dist\backup.exe" "backup.exe" >nul
    echo [OK] backup.exe created
) else (
    echo [ERROR] backup.exe not found
    pause
    exit /b 1
)

echo.

REM ====================================================================
REM Git commit and push
REM ====================================================================
echo [5/5] Committing and pushing...

git add backup.exe

REM Check if there are changes
git diff --cached --quiet
if %errorlevel% equ 0 (
    echo [INFO] No changes to commit
    goto :done
)

REM Commit
echo Enter commit message (or press Enter for default):
set /p COMMIT_MSG=""
if "%COMMIT_MSG%"=="" set COMMIT_MSG=Update backup.exe

git commit -m "%COMMIT_MSG%"
if %errorlevel% neq 0 (
    echo [ERROR] Commit failed
    pause
    exit /b 1
)

REM Push
git push origin main
if %errorlevel% neq 0 (
    echo [ERROR] Push failed
    echo Try manually: cd %WORK_DIR% && git push origin main
    pause
    exit /b 1
)

echo [OK] Pushed to GitHub

:done
echo.
echo ========================================
echo Complete!
echo ========================================
echo.
echo Output: %WORK_DIR%\backup.exe
echo GitHub: https://github.com/dev-sean-2016/medi101-backup
echo.

REM Clean build folders
echo Clean build folders? (Y/N)
set /p CLEANUP=""
if /i "%CLEANUP%"=="Y" (
    if exist "build" rmdir /s /q build
    if exist "dist" rmdir /s /q dist
    if exist "backup.spec" del /q backup.spec
    echo [OK] Cleaned
)

echo.
echo Done!
pause
