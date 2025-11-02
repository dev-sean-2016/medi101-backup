@echo off
chcp 65001 >nul
REM ====================================================================
REM Medi101 백업 프로그램 빌드 및 배포 스크립트 (개발자용)
REM 
REM 이 스크립트는 다음을 자동으로 수행합니다:
REM 1. Git 설치 확인 및 자동 설치
REM 2. Python 설치 확인 및 안내
REM 3. 저장소 클론 또는 업데이트
REM 4. Python 패키지 설치
REM 5. backup.exe 빌드
REM 6. Git에 커밋 및 푸시
REM 
REM 사용 방법:
REM   1. 이 파일을 원하는 위치에 저장
REM   2. 더블클릭하여 실행 (관리자 권한 권장)
REM ====================================================================

echo.
echo ========================================
echo Medi101 백업 프로그램 빌드 및 배포
echo ========================================
echo.

REM ====================================================================
REM 단계 1: Git 설치 확인 및 자동 설치
REM ====================================================================
echo ----------------------------------------
echo [1/6] Git 설치 확인
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

REM 방법 1: winget으로 설치 시도
echo [시도 1] winget으로 Git 설치 중...
winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] winget으로 Git 설치 완료
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    where git >nul 2>nul
    if %errorlevel% equ 0 (
        echo [OK] Git이 정상적으로 설치되었습니다.
        git --version
        goto :git_ok
    )
)

REM 방법 2: PowerShell로 Git 설치
echo [시도 2] PowerShell로 Git 설치 중...
echo (약 50MB 다운로드, 1-2분 소요...)

set TEMP_INSTALLER=%TEMP%\Git-Installer.exe

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $tag = (Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest').tag_name; $version = $tag -replace 'v',''; $url = \"https://github.com/git-for-windows/git/releases/download/$tag/Git-$version-64-bit.exe\"; Write-Host \"다운로드 중...\"; Invoke-WebRequest -Uri $url -OutFile '%TEMP_INSTALLER%' -UseBasicParsing; exit 0 } catch { Write-Host \"실패: $_\"; exit 1 } }"

if %errorlevel% neq 0 (
    echo [오류] Git 자동 설치 실패
    echo.
    echo 수동 설치 필요:
    echo   https://git-scm.com/download/win
    pause
    exit /b 1
)

echo Git 설치 중...
"%TEMP_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP-

timeout /t 5 /nobreak >nul
if exist "%TEMP_INSTALLER%" del /f /q "%TEMP_INSTALLER%"

set "PATH=%PATH%;C:\Program Files\Git\cmd"

where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [오류] Git 설치는 완료되었으나 실행 불가
    echo 컴퓨터 재시작 후 다시 실행해주세요.
    pause
    exit /b 1
)

:git_ok
echo.

REM ====================================================================
REM 단계 2: Python 설치 확인
REM ====================================================================
echo ----------------------------------------
echo [2/6] Python 설치 확인
echo ----------------------------------------

where python >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Python이 설치되어 있습니다.
    python --version
    goto :python_ok
)

echo [오류] Python이 설치되어 있지 않습니다.
echo.
echo Python 설치 방법:
echo   1. https://www.python.org/downloads/ 방문
echo   2. Python 3.8 이상 다운로드
echo   3. 설치 시 "Add Python to PATH" 체크 필수!
echo   4. 설치 완료 후 이 스크립트 다시 실행
echo.
echo 브라우저를 여시겠습니까? (Y/N)
set /p OPEN_PY="입력: "

if /i "%OPEN_PY%"=="Y" (
    start https://www.python.org/downloads/
)

pause
exit /b 1

:python_ok
echo.

REM ====================================================================
REM 단계 3: 작업 디렉토리 선택
REM ====================================================================
echo ----------------------------------------
echo [3/6] 작업 디렉토리 설정
echo ----------------------------------------
echo.

set WORK_DIR=%USERPROFILE%\medi101-dev
echo 작업 디렉토리: %WORK_DIR%
echo.

REM 디렉토리가 있으면 업데이트, 없으면 클론
if exist "%WORK_DIR%\.git" (
    echo [OK] 기존 저장소를 업데이트합니다.
    cd /d "%WORK_DIR%"
    
    echo git pull 실행 중...
    git pull
    
    if %errorlevel% neq 0 (
        echo [경고] git pull 실패. 계속 진행합니다.
    )
    
    goto :repo_ok
)

REM 저장소 클론
echo 저장소를 클론합니다...
echo URL: https://github.com/dev-sean-2016/medi101-backup.git
echo.

git clone https://github.com/dev-sean-2016/medi101-backup.git "%WORK_DIR%"

if %errorlevel% neq 0 (
    echo [오류] Git 클론 실패
    pause
    exit /b 1
)

cd /d "%WORK_DIR%"

:repo_ok
echo [OK] 저장소 준비 완료
echo.

REM ====================================================================
REM 단계 4: Python 패키지 설치
REM ====================================================================
echo ----------------------------------------
echo [4/6] Python 패키지 설치
echo ----------------------------------------
echo.

if not exist "requirements.txt" (
    echo [경고] requirements.txt 파일이 없습니다.
    goto :skip_install
)

echo pip 업그레이드 중...
python -m pip install --quiet --upgrade pip

echo.
echo 필요한 패키지 설치 중...
python -m pip install --quiet -r requirements.txt

if %errorlevel% neq 0 (
    echo [오류] 패키지 설치 실패
    pause
    exit /b 1
)

echo [OK] 패키지 설치 완료
goto :packages_ok

:skip_install
echo [스킵] 패키지 설치 생략

:packages_ok
echo.

REM ====================================================================
REM 단계 5: backup.exe 빌드
REM ====================================================================
echo ----------------------------------------
echo [5/6] backup.exe 빌드
echo ----------------------------------------
echo.

REM 기존 빌드 파일 정리
if exist "build" rmdir /s /q build
if exist "dist" rmdir /s /q dist
if exist "backup.spec" del /q backup.spec

echo PyInstaller로 빌드 중...
echo (약 1-2분 소요, 잠시만 기다려주세요...)
echo.

pyinstaller --onefile ^
    --name=backup ^
    --console ^
    --clean ^
    backup.py

if %errorlevel% neq 0 (
    echo.
    echo [오류] 빌드 실패
    pause
    exit /b 1
)

REM backup.exe를 프로젝트 루트로 복사
if exist "dist\backup.exe" (
    echo.
    echo backup.exe를 프로젝트 루트로 복사 중...
    copy /Y "dist\backup.exe" "backup.exe" >nul
    
    if %errorlevel% equ 0 (
        echo [OK] 복사 완료
    )
)

REM 파일 크기 확인
if exist "backup.exe" (
    for %%A in ("backup.exe") do set SIZE=%%~zA
    set /A SIZE_MB=%SIZE% / 1048576
    echo [OK] backup.exe 생성 완료 (크기: %SIZE_MB% MB)
) else (
    echo [오류] backup.exe 파일이 생성되지 않았습니다.
    pause
    exit /b 1
)

echo.

REM ====================================================================
REM 단계 6: Git 커밋 및 푸시
REM ====================================================================
echo ----------------------------------------
echo [6/6] Git 커밋 및 푸시
echo ----------------------------------------
echo.

REM 변경사항 확인
git status --short

echo.
echo backup.exe를 Git에 추가합니다...
git add backup.exe

REM 변경사항이 있는지 확인
git diff --cached --quiet
if %errorlevel% equ 0 (
    echo [알림] 변경사항이 없습니다. 푸시를 생략합니다.
    goto :done
)

REM 커밋 메시지 입력
echo.
echo 커밋 메시지를 입력해주세요.
echo (예: backup.exe 업데이트, 버그 수정, 새 기능 추가 등)
echo.
set /p COMMIT_MSG="커밋 메시지: "

if "%COMMIT_MSG%"=="" (
    set COMMIT_MSG=backup.exe 업데이트
)

echo.
echo 커밋 중...
git commit -m "%COMMIT_MSG%"

if %errorlevel% neq 0 (
    echo [오류] 커밋 실패
    pause
    exit /b 1
)

echo.
echo GitHub에 푸시 중...
git push origin main

if %errorlevel% neq 0 (
    echo.
    echo [오류] 푸시 실패
    echo.
    echo 가능한 원인:
    echo   1. 인터넷 연결 문제
    echo   2. Git 인증 문제 (GitHub 로그인 필요)
    echo   3. 권한 문제
    echo.
    echo 수동으로 푸시하려면:
    echo   cd %WORK_DIR%
    echo   git push origin main
    echo.
    pause
    exit /b 1
)

:done
echo.
echo ========================================
echo 빌드 및 배포 완료!
echo ========================================
echo.
echo 작업 내용:
echo   ✅ Git 설치/확인
echo   ✅ Python 설치/확인
echo   ✅ 저장소 클론/업데이트
echo   ✅ 패키지 설치
echo   ✅ backup.exe 빌드
echo   ✅ Git 커밋 및 푸시
echo.
echo 생성된 파일:
echo   - %WORK_DIR%\backup.exe
echo.
echo GitHub 저장소:
echo   https://github.com/dev-sean-2016/medi101-backup
echo.
echo 다음 단계:
echo   운영 서버에서 setup.bat을 실행하면
echo   자동으로 최신 backup.exe를 다운로드합니다.
echo.

REM 빌드 폴더 정리 여부 확인
echo.
echo build, dist 폴더를 삭제하시겠습니까? (Y/N)
set /p CLEANUP="입력: "

if /i "%CLEANUP%"=="Y" (
    if exist "build" rmdir /s /q build
    if exist "dist" rmdir /s /q dist
    if exist "backup.spec" del /q backup.spec
    echo [OK] 임시 폴더 정리 완료
)

echo.
echo 작업을 완료했습니다!
pause

