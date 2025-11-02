@echo off
REM ====================================================================
REM EXE Build Script
REM - Convert Python script to Windows executable
REM - Uses PyInstaller
REM ====================================================================

echo.
echo ========================================
echo EXE Build Starting
echo ========================================
echo.

REM Navigate to current directory
cd /d "%~dp0"

REM Check Python installation
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python not installed
    echo Download from: https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo [1/4] Python version check
python --version
echo.

REM Install PyInstaller
echo [2/4] Installing/updating PyInstaller
python -m pip install --quiet --upgrade pyinstaller
if %errorlevel% neq 0 (
    echo [ERROR] PyInstaller installation failed
    pause
    exit /b 1
)
echo PyInstaller installation complete
echo.

REM Install required packages
echo [3/4] Installing required packages
if exist "requirements.txt" (
    python -m pip install --quiet -r requirements.txt
    echo Package installation complete
) else (
    echo [WARNING] requirements.txt not found
)
echo.

REM Clean previous build
if exist "build" (
    echo Removing old build folder...
    rmdir /s /q build
)
if exist "dist" (
    echo Removing old dist folder...
    rmdir /s /q dist
)
if exist "backup.spec" (
    echo Removing old spec file...
    del /q backup.spec
)

REM Build EXE
echo [4/4] Building EXE...
echo.
pyinstaller --onefile ^
    --name=backup ^
    --icon=NONE ^
    --console ^
    --clean ^
    backup.py

if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo [ERROR] Build failed
    echo ========================================
    echo.
    pause
    exit /b 1
)

REM Copy backup.exe to project root (for Git commit)
if exist "dist\backup.exe" (
    echo.
    echo Copying backup.exe to project root...
    copy /Y "dist\backup.exe" "backup.exe" >nul
    if %errorlevel% equ 0 (
        echo Copy complete: backup.exe
    ) else (
        echo [WARNING] Copy failed
    )
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Generated files:
echo   - dist\backup.exe (PyInstaller output)
echo   - backup.exe (For Git commit - project root)
echo.
echo Next steps:
echo   1. Test backup.exe
echo   2. Commit to Git
echo      git add backup.exe
echo      git commit -m "Update backup.exe"
echo      git push origin main
echo.
echo Important:
echo   - DO NOT commit config.json (excluded in .gitignore)
echo   - Only commit backup.exe
echo.

REM Test instructions
echo Test instructions:
echo   1. Copy config.json.template to config.json
echo   2. Edit config.json with actual values
echo   3. Double-click backup.exe to run
echo   4. Check backup.log for results
echo.

pause
