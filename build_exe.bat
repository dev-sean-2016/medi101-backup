@echo off
chcp 65001 >nul
REM ====================================================================
REM EXE 빌드 스크립트
REM - Python 스크립트를 Windows 실행 파일로 변환
REM - PyInstaller 사용
REM ====================================================================

echo.
echo ========================================
echo EXE 빌드 시작
echo ========================================
echo.

REM 현재 디렉토리로 이동
cd /d "%~dp0"

REM Python 설치 확인
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [오류] Python이 설치되어 있지 않습니다.
    echo https://www.python.org/downloads/ 에서 Python을 설치해주세요.
    echo.
    pause
    exit /b 1
)

echo [1/4] Python 버전 확인
python --version
echo.

REM PyInstaller 설치
echo [2/4] PyInstaller 설치/업데이트
python -m pip install --quiet --upgrade pyinstaller
if %errorlevel% neq 0 (
    echo [오류] PyInstaller 설치 실패
    pause
    exit /b 1
)
echo PyInstaller 설치 완료
echo.

REM 필요한 패키지 설치
echo [3/4] 필요한 패키지 설치
if exist "requirements.txt" (
    python -m pip install --quiet -r requirements.txt
    echo 패키지 설치 완료
) else (
    echo [경고] requirements.txt 파일이 없습니다.
)
echo.

REM 기존 빌드 파일 정리
if exist "build" (
    echo 기존 build 폴더 삭제 중...
    rmdir /s /q build
)
if exist "dist" (
    echo 기존 dist 폴더 삭제 중...
    rmdir /s /q dist
)
if exist "backup.spec" (
    echo 기존 spec 파일 삭제 중...
    del /q backup.spec
)

REM EXE 빌드
echo [4/4] EXE 빌드 중...
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
    echo [오류] 빌드 실패
    echo ========================================
    echo.
    pause
    exit /b 1
)

REM backup.exe를 프로젝트 루트로 복사 (Git 커밋용)
if exist "dist\backup.exe" (
    echo.
    echo backup.exe를 프로젝트 루트로 복사 중...
    copy /Y "dist\backup.exe" "backup.exe"
    if %errorlevel% equ 0 (
        echo 복사 완료: backup.exe
    ) else (
        echo [경고] 복사 실패
    )
)

echo.
echo ========================================
echo [성공] 빌드 완료!
echo ========================================
echo.
echo 생성된 파일:
echo   - dist\backup.exe (PyInstaller 빌드 결과)
echo   - backup.exe (Git 커밋용 - 프로젝트 루트)
echo.
echo 다음 단계:
echo   1. backup.exe를 테스트
echo   2. Git에 커밋
echo      git add backup.exe
echo      git commit -m "백업 프로그램 업데이트"
echo      git push origin main
echo.
echo 주의사항:
echo   - config.json은 절대 커밋하지 마세요 (.gitignore에 포함됨)
echo   - backup.exe만 커밋하면 됩니다
echo.

REM 테스트 실행 안내
echo 테스트 방법:
echo   1. config.json.template을 config.json으로 복사
echo   2. config.json에 실제 값 입력
echo   3. backup.exe 더블클릭하여 실행
echo   4. backup.log 파일에서 결과 확인
echo.

pause

