@echo off
chcp 65001 >nul
REM ====================================================================
REM 백업 프로그램 업데이트 및 실행 스크립트
REM - Git pull로 최신 backup.exe 받기
REM - backup.exe 실행 (Python 설치 불필요)
REM ====================================================================

echo.
echo ========================================
echo 백업 프로그램 시작
echo 실행 시간: %date% %time%
echo ========================================
echo.

REM 현재 스크립트의 디렉토리로 이동
cd /d "%~dp0"

REM Git 설치 확인
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [오류] Git이 설치되어 있지 않습니다.
    echo install_git.bat 파일을 먼저 실행해주세요.
    echo.
    pause
    exit /b 1
)

REM Git 저장소 확인
if not exist ".git" (
    echo [경고] 이 폴더는 Git 저장소가 아닙니다.
    echo Git 저장소를 초기화하거나 클론해주세요.
    echo.
    echo 예시:
    echo   git init
    echo   git remote add origin [저장소 URL]
    echo   git pull origin main
    echo.
    pause
    exit /b 1
)

REM 최신 코드 받기
echo.
echo ----------------------------------------
echo [1/2] Git Pull - 최신 backup.exe 다운로드
echo ----------------------------------------
git pull
if %errorlevel% neq 0 (
    echo [경고] Git pull 실패. 인터넷 연결을 확인하거나 수동으로 git pull을 실행해주세요.
    echo 기존 backup.exe로 계속 진행합니다...
)

REM backup.exe 파일 확인
if not exist "backup.exe" (
    echo.
    echo [오류] backup.exe 파일이 없습니다.
    echo.
    echo 개발자에게 다음을 요청하세요:
    echo   1. build_exe.bat 실행하여 backup.exe 생성
    echo   2. backup.exe를 Git에 커밋
    echo.
    pause
    exit /b 1
)

REM config.json 파일 확인
if not exist "config.json" (
    echo.
    echo [오류] config.json 파일이 없습니다.
    echo.
    echo 설정 방법:
    echo   1. config.json.template 파일을 config.json으로 복사
    echo   2. config.json 파일을 열어서 실제 값 입력
    echo      - Access Key, Secret Key
    echo      - 사업자 번호
    echo      - 소스 경로
    echo.
    pause
    exit /b 1
)

REM 백업 실행
echo.
echo ----------------------------------------
echo [2/2] 백업 실행
echo ----------------------------------------
backup.exe

REM 결과 확인
if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo 백업 완료!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo [오류] 백업 실행 중 오류 발생
    echo backup.log 파일을 확인해주세요.
    echo ========================================
)

echo.
REM 작업 스케줄러로 실행될 때는 자동 종료
REM 수동 실행시에만 pause
if "%1" neq "auto" (
    pause
)

