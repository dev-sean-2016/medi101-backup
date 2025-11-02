@echo off
chcp 65001 >nul
REM ====================================================================
REM Windows 작업 스케줄러 제거 스크립트
REM - 등록된 백업 작업을 제거
REM ====================================================================

echo.
echo ========================================
echo 작업 스케줄러 제거
echo ========================================
echo.

REM 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [오류] 이 스크립트는 관리자 권한이 필요합니다.
    echo 마우스 오른쪽 버튼 클릭 후 "관리자 권한으로 실행"을 선택해주세요.
    echo.
    pause
    exit /b 1
)

set TASK_NAME=KakaoCloudBackup

REM 작업 존재 확인
schtasks /query /tn %TASK_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo [알림] "%TASK_NAME%" 작업이 등록되어 있지 않습니다.
    echo.
    pause
    exit /b 0
)

REM 작업 삭제
echo 작업 삭제 중: %TASK_NAME%
schtasks /delete /tn %TASK_NAME% /f

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [성공] 작업이 제거되었습니다.
    echo ========================================
) else (
    echo.
    echo ========================================
    echo [오류] 작업 제거 실패
    echo ========================================
)

echo.
pause

