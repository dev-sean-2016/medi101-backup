@echo off
chcp 65001 >nul
REM ====================================================================
REM Medi101 백업 프로그램 원클릭 설치 스크립트
REM 
REM 이 스크립트는 다음을 자동으로 수행합니다:
REM 1. Git 설치 확인 및 설치 안내
REM 2. 백업 프로그램 저장소 클론
REM 3. 설정 파일 생성 안내
REM 4. 작업 스케줄러 등록
REM 
REM 사용 방법:
REM   1. 이 파일을 원하는 위치에 다운로드
REM   2. 마우스 오른쪽 클릭 → "관리자 권한으로 실행"
REM ====================================================================

echo.
echo ========================================
echo Medi101 백업 프로그램 설치
echo ========================================
echo.

REM 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [오류] 이 스크립트는 관리자 권한이 필요합니다.
    echo.
    echo 마우스 오른쪽 버튼 클릭 후 
    echo "관리자 권한으로 실행"을 선택해주세요.
    echo.
    pause
    exit /b 1
)

echo [1/5] 관리자 권한 확인 완료
echo.

REM ====================================================================
REM 단계 2: Git 설치 확인 및 자동 설치
REM ====================================================================
echo ----------------------------------------
echo [2/5] Git 설치 확인 및 자동 설치
echo ----------------------------------------

where git >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Git이 이미 설치되어 있습니다.
    git --version
    goto :git_ok
)

echo [알림] Git이 설치되어 있지 않습니다.
echo Git을 자동으로 설치합니다...
echo.

REM 방법 1: winget으로 설치 시도 (Windows 10/11)
echo [시도 1] winget으로 Git 설치 중...
winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] winget으로 Git 설치 완료
    
    REM PATH 환경변수에 Git 추가
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    
    REM Git 설치 확인
    where git >nul 2>nul
    if %errorlevel% equ 0 (
        echo [OK] Git이 정상적으로 설치되었습니다.
        git --version
        goto :git_ok
    )
)

REM 방법 2: PowerShell로 Git 설치 파일 다운로드 후 설치
echo [시도 2] PowerShell로 Git 설치 파일 다운로드 중...
echo (약 50MB, 시간이 걸릴 수 있습니다...)

REM 임시 폴더에 다운로드
set TEMP_INSTALLER=%TEMP%\Git-Installer.exe

REM Git 최신 버전 다운로드 (Git for Windows)
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $tag = (Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest').tag_name; $version = $tag -replace 'v',''; $url = \"https://github.com/git-for-windows/git/releases/download/$tag/Git-$version-64-bit.exe\"; Write-Host \"다운로드 URL: $url\"; Invoke-WebRequest -Uri $url -OutFile '%TEMP_INSTALLER%' -UseBasicParsing; exit 0 } catch { Write-Host \"다운로드 실패: $_\"; exit 1 } }"

if %errorlevel% neq 0 (
    echo [오류] Git 설치 파일 다운로드 실패
    echo.
    echo 수동 설치가 필요합니다:
    echo   1. https://git-scm.com/download/win 방문
    echo   2. Git 다운로드 및 설치
    echo   3. 이 스크립트를 다시 실행
    echo.
    pause
    exit /b 1
)

echo [OK] 다운로드 완료
echo.
echo Git 설치 중... (자동 설치, 기본 설정 사용)
echo (약 1-2분 소요, 잠시만 기다려주세요...)

REM 자동 설치 (/VERYSILENT: 조용히 설치, /NORESTART: 재시작 안 함)
"%TEMP_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"

if %errorlevel% neq 0 (
    echo [오류] Git 설치 실패
    pause
    exit /b 1
)

REM 설치 완료 대기 (설치 파일이 백그라운드에서 실행됨)
echo 설치 완료 대기 중...
timeout /t 5 /nobreak >nul

REM 설치 파일 삭제
if exist "%TEMP_INSTALLER%" (
    del /f /q "%TEMP_INSTALLER%" >nul 2>&1
)

REM PATH 환경변수에 Git 추가
set "PATH=%PATH%;C:\Program Files\Git\cmd"

REM Git 설치 확인
where git >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Git이 정상적으로 설치되었습니다!
    git --version
    goto :git_ok
)

echo.
echo [오류] Git 설치는 완료되었으나 실행할 수 없습니다.
echo 컴퓨터를 재시작한 후 이 스크립트를 다시 실행해주세요.
echo.
pause
exit /b 1

:git_ok
echo.

REM ====================================================================
REM 단계 3: 설치 경로 선택
REM ====================================================================
echo ----------------------------------------
echo [3/5] 설치 경로 선택
echo ----------------------------------------
echo.
echo 백업 프로그램을 설치할 경로를 선택해주세요.
echo 기본 경로: C:\medi101-backup
echo.
set /p INSTALL_PATH="설치 경로 (Enter = 기본 경로): "

if "%INSTALL_PATH%"=="" (
    set INSTALL_PATH=C:\medi101-backup
)

echo.
echo 설치 경로: %INSTALL_PATH%
echo.

REM 디렉토리가 이미 존재하는지 확인
if exist "%INSTALL_PATH%" (
    echo [경고] 이미 해당 경로에 폴더가 존재합니다.
    echo.
    dir /b "%INSTALL_PATH%"
    echo.
    echo 기존 폴더를 삭제하고 새로 설치하시겠습니까? (Y/N)
    set /p DELETE_EXISTING="입력: "
    
    if /i "%DELETE_EXISTING%"=="Y" (
        echo 기존 폴더 삭제 중...
        rmdir /s /q "%INSTALL_PATH%"
    ) else (
        echo 설치를 취소합니다.
        pause
        exit /b 0
    )
)

echo.

REM ====================================================================
REM 단계 4: Git 저장소 클론
REM ====================================================================
echo ----------------------------------------
echo [4/5] 백업 프로그램 다운로드
echo ----------------------------------------
echo.
echo Git 저장소에서 최신 버전을 다운로드합니다...
echo 저장소: https://github.com/dev-sean-2016/medi101-backup.git
echo.

git clone https://github.com/dev-sean-2016/medi101-backup.git "%INSTALL_PATH%"

if %errorlevel% neq 0 (
    echo.
    echo [오류] Git 저장소 클론에 실패했습니다.
    echo.
    echo 가능한 원인:
    echo   1. 인터넷 연결 문제
    echo   2. Git 저장소 주소 오류
    echo   3. Git 저장소 접근 권한 문제
    echo.
    echo 해결 방법:
    echo   1. 인터넷 연결을 확인해주세요
    echo   2. 저장소가 Public인지 확인해주세요
    echo   3. 잠시 후 다시 시도해주세요
    echo.
    pause
    exit /b 1
)

echo [OK] 다운로드 완료
echo.

REM 설치 경로로 이동
cd /d "%INSTALL_PATH%"

REM ====================================================================
REM 단계 5: 설정 파일 생성
REM ====================================================================
echo ----------------------------------------
echo [5/5] 설정 파일 생성
echo ----------------------------------------
echo.

REM config.json이 이미 있는지 확인
if exist "config.json" (
    echo [OK] config.json 파일이 이미 존재합니다.
    goto :config_ok
)

REM config.json.template에서 복사
if exist "config.json.template" (
    copy config.json.template config.json >nul
    echo [OK] config.json 파일 생성 완료
    echo.
    echo [중요] config.json 파일을 수정해야 합니다!
    echo.
    echo 수정할 항목:
    echo   - access_key: Kakao Cloud Access Key
    echo   - secret_key: Kakao Cloud Secret Key
    echo   - business_number: 사업자 번호
    echo   - service_name: 서비스 명 (기본: YSR2000)
    echo   - source_paths: 백업할 폴더 경로 (기본: C:\backup\WEEKLY)
    echo   - schedule_time: 실행 시간 (기본: 07:00)
    echo.
    echo 지금 config.json 파일을 여시겠습니까? (Y/N)
    set /p OPEN_CONFIG="입력: "
    
    if /i "%OPEN_CONFIG%"=="Y" (
        notepad config.json
    )
) else (
    echo [경고] config.json.template 파일이 없습니다.
    echo 수동으로 config.json 파일을 생성해주세요.
)

:config_ok
echo.

REM ====================================================================
REM 단계 6: backup.exe 파일 확인
REM ====================================================================
echo ----------------------------------------
echo [추가] backup.exe 파일 확인
echo ----------------------------------------
echo.

if exist "backup.exe" (
    echo [OK] backup.exe 파일이 존재합니다.
) else (
    echo [경고] backup.exe 파일이 없습니다.
    echo.
    echo backup.exe 파일은 백업 실행에 필요한 파일입니다.
    echo Git 저장소에 backup.exe가 커밋되어 있는지 확인해주세요.
    echo.
    echo 개발자에게 요청:
    echo   1. build_exe.bat 실행
    echo   2. backup.exe를 Git에 커밋
    echo.
    pause
    exit /b 1
)

echo.

REM ====================================================================
REM 단계 7: 작업 스케줄러 등록
REM ====================================================================
echo ----------------------------------------
echo [마지막] 작업 스케줄러 등록
echo ----------------------------------------
echo.
echo 매일 자동으로 백업을 실행하도록 등록합니다.
echo.

set TASK_NAME=Medi101Backup
set SCHEDULE_TIME=07:00

REM config.json에서 실행 시간 읽기 시도 (선택사항)
if exist "config.json" (
    echo config.json에서 실행 시간을 확인합니다...
    REM 간단한 방법: findstr로 schedule_time 찾기
    for /f "tokens=2 delims=:, " %%a in ('findstr /i "schedule_time" config.json') do (
        set SCHEDULE_TIME=%%a
    )
    REM 따옴표 제거
    set SCHEDULE_TIME=%SCHEDULE_TIME:"=%
)

echo 실행 시간: 매일 %SCHEDULE_TIME%
echo.

REM 기존 작업 삭제 (있는 경우)
schtasks /query /tn %TASK_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo 기존 작업이 존재합니다. 삭제 중...
    schtasks /delete /tn %TASK_NAME% /f >nul
)

REM 작업 스케줄러 등록
schtasks /create ^
    /tn "%TASK_NAME%" ^
    /tr "\"%INSTALL_PATH%\update_and_run.bat\" auto" ^
    /sc daily ^
    /st %SCHEDULE_TIME% ^
    /ru SYSTEM ^
    /rl HIGHEST ^
    /f >nul

if %errorlevel% equ 0 (
    echo [OK] 작업 스케줄러에 등록 완료!
) else (
    echo [오류] 작업 스케줄러 등록에 실패했습니다.
    pause
    exit /b 1
)

echo.

REM ====================================================================
REM 설치 완료
REM ====================================================================
echo.
echo ========================================
echo 설치 완료!
echo ========================================
echo.
echo 설치 정보:
echo   - 설치 경로: %INSTALL_PATH%
echo   - 작업 이름: %TASK_NAME%
echo   - 실행 시간: 매일 %SCHEDULE_TIME%
echo.
echo 다음 단계:
echo   1. config.json 파일 수정 (필수)
echo      notepad %INSTALL_PATH%\config.json
echo.
echo   2. 수동 테스트 실행
echo      %INSTALL_PATH%\update_and_run.bat
echo.
echo   3. 로그 확인
echo      notepad %INSTALL_PATH%\backup.log
echo.
echo 작업 스케줄러 확인:
echo   - 작업 스케줄러 프로그램 실행
echo   - "%TASK_NAME%" 검색
echo.
echo 작업 스케줄러 수동 실행:
echo   schtasks /run /tn "%TASK_NAME%"
echo.
echo 작업 스케줄러 제거:
echo   schtasks /delete /tn "%TASK_NAME%" /f
echo.
echo 지금 config.json을 수정하시겠습니까? (Y/N)
set /p EDIT_NOW="입력: "

if /i "%EDIT_NOW%"=="Y" (
    notepad "%INSTALL_PATH%\config.json"
)

echo.
echo 감사합니다!
echo.
pause

