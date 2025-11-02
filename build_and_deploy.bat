@echo off
REM ====================================================================
REM Medi101 Backup - Build and Deploy
REM 
REM This script: Build → Push
REM ====================================================================

echo.
echo ========================================
echo Build and Deploy
echo ========================================
echo.

REM ====================================================================
REM Build backup.exe
REM ====================================================================
echo [1/2] Building backup.exe...

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
    if exist "backup.exe" (
        echo [OK] backup.exe created
        for %%A in ("backup.exe") do echo       Size: %%~zA bytes
    ) else (
        echo [ERROR] Copy failed
        pause
        exit /b 1
    )
) else (
    echo [ERROR] backup.exe not found in dist folder
    pause
    exit /b 1
)

echo.

REM ====================================================================
REM Git commit and push
REM ====================================================================
echo [2/2] Committing and pushing...

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
