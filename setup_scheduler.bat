@echo off
chcp 65001 >nul
REM ====================================================================
REM Windows 작업 스케줄러 등록 스크립트
REM - 매일 지정된 시간에 백업 프로그램을 자동 실행하도록 등록
REM ====================================================================

echo.
echo ========================================
echo 작업 스케줄러 등록
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

REM 현재 디렉토리 경로
set CURRENT_DIR=%~dp0
set TASK_NAME=KakaoCloudBackup

echo 작업 이름: %TASK_NAME%
echo 스크립트 경로: %CURRENT_DIR%update_and_run.bat
echo.

REM 실행 시간 설정 (기본값: 07:00)
REM config.json에서 schedule_time을 확인하고 싶다면 수동으로 변경
set SCHEDULE_TIME=07:00

echo 실행 시간: 매일 %SCHEDULE_TIME%
echo.

REM 기존 작업 삭제 (있는 경우)
schtasks /query /tn %TASK_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo 기존 작업이 존재합니다. 삭제 중...
    schtasks /delete /tn %TASK_NAME% /f
)

REM 작업 스케줄러 등록
echo.
echo 작업 스케줄러에 등록 중...
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
    echo [성공] 작업 스케줄러에 등록되었습니다!
    echo ========================================
    echo.
    echo 작업 이름: %TASK_NAME%
    echo 실행 시간: 매일 %SCHEDULE_TIME%
    echo.
    echo 확인 방법:
    echo   1. "작업 스케줄러" 프로그램 실행
    echo   2. "작업 스케줄러 라이브러리"에서 "%TASK_NAME%" 검색
    echo.
    echo 수동 실행:
    echo   schtasks /run /tn "%TASK_NAME%"
    echo.
) else (
    echo.
    echo ========================================
    echo [오류] 작업 스케줄러 등록 실패
    echo ========================================
    echo.
)

pause

