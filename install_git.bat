@echo off
chcp 65001 >nul
REM ====================================================================
REM Git 설치 스크립트
REM - Git이 설치되어 있지 않으면 자동으로 설치
REM ====================================================================

echo.
echo ========================================
echo Git 설치 확인 중...
echo ========================================
echo.

REM Git 설치 여부 확인
where git >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Git이 이미 설치되어 있습니다.
    git --version
    goto :end
)

echo [경고] Git이 설치되어 있지 않습니다.
echo.
echo Git을 설치하려면 아래 URL에서 다운로드하여 설치해주세요:
echo https://git-scm.com/download/win
echo.
echo 설치 후 이 스크립트를 다시 실행해주세요.
echo.
pause
exit /b 1

:end
echo.
pause

