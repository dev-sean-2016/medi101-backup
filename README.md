# Kakao Cloud Object Storage 백업 프로그램

Windows에서 실행되는 자동 백업 프로그램입니다. 지정된 경로의 파일들을 Kakao Cloud Object Storage에 백업합니다.

## 📋 목차

- [주요 기능](#주요-기능)
- [파일 구조](#파일-구조)
- [개발자용: 개발 환경 설정](#개발자용-개발-환경-설정)
- [운영자용: 설치 및 실행](#운영자용-설치-및-실행)
- [백업 로직 설명](#백업-로직-설명)
- [문제 해결](#문제-해결)

---

## 🎯 주요 기능

✅ **자동 백업**: Windows 작업 스케줄러로 매일 자동 실행  
✅ **대용량 지원**: 7GB+ 파일도 멀티파트 업로드로 안정적 처리  
✅ **자동 업데이트**: Git pull로 최신 버전 자동 다운로드  
✅ **파일 정리**: 백업 파일이 8개 이상이면 오래된 파일 자동 삭제  
✅ **Python 불필요**: 단일 EXE 파일로 배포 (Python 설치 안 해도 됨)

---

## 📁 파일 구조

### Git에 포함되는 파일 (배포용)
```
s3cp/
├── backup.exe                 # 백업 실행 파일 (Python 불필요)
├── backup.py                  # 백업 스크립트 소스 코드
├── config.json.template       # 설정 파일 템플릿
├── requirements.txt           # Python 패키지 목록
├── .gitignore                 # Git 제외 파일 목록
├── README.md                  # 이 파일
│
├── update_and_run.bat         # Git pull + backup.exe 실행
├── setup_scheduler.bat        # 작업 스케줄러 등록 (관리자 권한 필요)
├── remove_scheduler.bat       # 작업 스케줄러 제거
├── install_git.bat            # Git 설치 확인
└── build_exe.bat              # 개발자용: EXE 빌드 스크립트
```

### Git에 포함되지 않는 파일 (로컬 전용)
```
s3cp/
├── config.json                # 실제 설정 파일 (민감 정보 포함)
├── backup.log                 # 백업 실행 로그
├── build/                     # PyInstaller 빌드 임시 폴더
└── dist/                      # PyInstaller 빌드 결과 폴더
```

---

## 🔧 개발자용: 개발 환경 설정

### 1. Python 설치
Python 3.8 이상 필요  
https://www.python.org/downloads/

### 2. 패키지 설치
```bash
pip install -r requirements.txt
```

### 3. 설정 파일 생성
```bash
copy config.json.template config.json
# config.json 파일을 열어서 실제 값 입력
```

### 4. 테스트 실행
```bash
python backup.py
```

### 5. EXE 빌드
```bash
build_exe.bat
# 또는
pyinstaller --onefile --name=backup --console backup.py
```

### 6. Git 커밋
```bash
git add backup.exe
git commit -m "백업 프로그램 업데이트"
git push origin main
```

**⚠️ 주의**: `config.json`은 절대 커밋하지 마세요 (`.gitignore`에 이미 포함됨)

---

## 💻 운영자용: 원클릭 설치 및 실행

### 필수 요구사항
- Windows 10 이상 (권장)
- 인터넷 연결
- **Git 자동 설치** ✅
- **Python 설치 불필요** ✅

### 🚀 원클릭 설치 (가장 쉬운 방법)

**단 하나의 파일로 모든 것을 자동 설치!**

#### 1단계: setup.bat 다운로드
```
1. https://github.com/dev-sean-2016/medi101-backup 방문
2. setup.bat 파일 다운로드
```

#### 2단계: 관리자 권한으로 실행
```
setup.bat 파일 마우스 오른쪽 클릭
→ "관리자 권한으로 실행" 선택
```

#### 3단계: 자동 설치 완료!
스크립트가 자동으로:
- ✅ Git 자동 설치 (없는 경우)
- ✅ 백업 프로그램 다운로드
- ✅ config.json 생성
- ✅ 작업 스케줄러 등록

**끝! 이제 매일 자동으로 백업됩니다.**

---

### 📝 수동 설치 (고급 사용자용)

원클릭 설치가 실패하는 경우에만 아래 방법을 사용하세요.

### 1단계: Git 설치
```bash
install_git.bat 실행
```
- Git이 자동으로 설치됨
- 수동 설치: https://git-scm.com/download/win

### 2단계: Git 저장소 클론
```bash
cd C:\원하는경로
git clone https://github.com/dev-sean-2016/medi101-backup.git
cd medi101-backup
```

### 3단계: 설정 파일 생성
```bash
# 1. config.json.template을 config.json으로 복사
copy config.json.template config.json

# 2. config.json 파일을 메모장으로 열기
notepad config.json

# 3. 아래 항목들 입력
```

#### config.json 설정 항목
```json
{
  "kakao_cloud": {
    "access_key": "실제 Access Key 입력",
    "secret_key": "실제 Secret Key 입력",
    "endpoint_url": "https://objectstorage.kr-central-2.kakaoi.io",
    "bucket_name": "medi101-backup-01",
    "region": "kr-central-2"
  },
  "backup": {
    "business_number": "사업자번호 입력 (예: 1234567890)",
    "service_name": "YSR2000",
    "source_paths": [
      "C:\\backup\\WEEKLY"
    ],
    "max_files_keep": 8,
    "schedule_time": "07:00"
  }
}
```

### 4단계: 수동 실행 테스트
```bash
update_and_run.bat 더블클릭
```
- Git pull 실행
- backup.exe 실행
- 결과를 backup.log 파일에서 확인

### 5단계: 작업 스케줄러 등록 (자동 실행)
```bash
setup_scheduler.bat을 마우스 오른쪽 버튼 클릭
→ "관리자 권한으로 실행" 선택
```

#### 작업 스케줄러 확인 방법
1. Windows 시작 메뉴 → "작업 스케줄러" 검색
2. "작업 스케줄러 라이브러리"에서 "KakaoCloudBackup" 검색
3. 등록된 작업 확인

#### 수동 실행 (테스트용)
```bash
schtasks /run /tn "KakaoCloudBackup"
```

#### 작업 스케줄러 제거
```bash
remove_scheduler.bat을 관리자 권한으로 실행
```

---

## 🔍 백업 로직 설명

### 파일 처리 규칙

#### 1. 로그 파일: `{서비스명}.log`
- 예: `YSR2000.log`
- **처리**: 매일 Kakao Cloud에 **덮어쓰기**
- **이유**: 최신 로그만 유지

#### 2. 타임스탬프 백업 파일: `{서비스명}_{YYYYMMDDHHMMSS}`
- 예: `YSR2000_20250829190000`
- **처리 조건**:
  - Kakao Cloud에 **동일 파일명이 없으면**: 업로드 **안 함**
  - Kakao Cloud에 **동일 파일명이 있으면**: 
    - 파일 크기 비교
    - 차이가 **20MB 이상**이면 **재업로드**
    - 차이가 **20MB 미만**이면 **스킵**

#### 3. 기타 파일
- **처리**: 무시 (업로드 안 함)

### 저장 경로
```
버킷: medi101-backup-01
경로: {사업자번호}/{파일명}

예시:
  1234567890/YSR2000.log
  1234567890/YSR2000_20250829190000
  1234567890/YSR2000_20250916190001
```

### 파일 정리
- 사업자번호 경로에 타임스탬프 백업 파일이 **8개 초과**하면
- **가장 오래된 파일부터 자동 삭제**
- 로그 파일(`.log`)은 개수에 포함 안 됨

---

## 🛠️ 문제 해결

### BAT 파일에서 한글이 깨져요
**증상**: BAT 파일 실행 시 한글이 ��� 또는 ???? 등으로 표시됨

**해결 방법 1 (자동)**: PowerShell 스크립트 실행
```powershell
# 저장소 폴더에서 실행
.\fix_encoding.ps1
```

**해결 방법 2 (수동)**: 메모장으로 저장
```
1. BAT 파일을 메모장으로 열기
2. 파일 → 다른 이름으로 저장
3. 인코딩: "UTF-8" 선택 (BOM 포함)
4. 저장
```

**해결 방법 3**: Git에서 다시 클론
```bash
# 저장소를 새로 클론하면 자동으로 올바른 인코딩 적용
git clone https://github.com/dev-sean-2016/medi101-backup.git
```

### backup.exe가 실행되지 않아요
**증상**: "backup.exe 파일이 없습니다" 오류
**해결**:
```bash
git pull  # 최신 backup.exe 다운로드
```

### config.json이 없다고 나와요
**해결**:
```bash
copy config.json.template config.json
notepad config.json  # 실제 값 입력
```

### Git pull이 실패해요
**원인**: 인터넷 연결 문제 또는 Git 저장소 설정 문제
**해결**:
```bash
# 인터넷 연결 확인
ping google.com

# Git 저장소 확인
git remote -v

# 수동으로 Git pull
git pull origin main
```

### 백업이 실패해요
**확인 사항**:
1. `backup.log` 파일 열어서 오류 메시지 확인
2. `config.json`의 Access Key, Secret Key 확인
3. 소스 경로(`C:\backup\WEEKLY`)가 존재하는지 확인
4. 인터넷 연결 확인

### 작업 스케줄러가 등록되지 않아요
**해결**: 
- `setup_scheduler.bat`을 **관리자 권한**으로 실행했는지 확인
- Windows 작업 스케줄러 서비스가 실행 중인지 확인

### 파일이 업로드되지 않아요
**확인**:
1. 파일명이 `{서비스명}.log` 또는 `{서비스명}_{YYYYMMDDHHMMSS}` 형식인지 확인
2. 타임스탬프 파일의 경우 Kakao Cloud에 이미 존재하는지 확인
3. `backup.log`에서 "[스킵]" 또는 "[업로드]" 메시지 확인

---

## 📊 로그 확인

### backup.log 파일
모든 백업 실행 결과가 저장됩니다.

**로그 예시**:
```
2025-11-02 07:00:01 - INFO - ================================================================================
2025-11-02 07:00:01 - INFO - 백업 시작: 2025-11-02 07:00:01
2025-11-02 07:00:01 - INFO - ================================================================================
2025-11-02 07:00:01 - INFO - 소스 경로 스캔: C:\backup\WEEKLY
2025-11-02 07:00:02 - INFO - [업로드] YSR2000.log - 로그 파일 - 매일 덮어쓰기
2025-11-02 07:00:02 - INFO - 업로드 시작: C:\backup\WEEKLY\YSR2000.log (0.01 MB) -> 1234567890/YSR2000.log
2025-11-02 07:00:03 - INFO - 업로드 완료: 1234567890/YSR2000.log
2025-11-02 07:00:03 - INFO - [업로드] YSR2000_20251011190001 - 파일 크기 차이 25.30 MB - 재업로드
2025-11-02 07:00:03 - INFO - 업로드 시작: C:\backup\WEEKLY\YSR2000_20251011190001 (7250.50 MB) -> 1234567890/YSR2000_20251011190001
2025-11-02 07:15:42 - INFO - 업로드 완료: 1234567890/YSR2000_20251011190001
2025-11-02 07:15:43 - INFO - [스킵] YSR2000_20250829190000 - S3에 파일이 없음 - 업로드 안 함
2025-11-02 07:15:43 - INFO - 파일 정리 시작: 1234567890/ 경로
2025-11-02 07:15:44 - INFO - 현재 백업 파일 개수: 9개 (최대: 8개)
2025-11-02 07:15:44 - INFO - 오래된 파일 삭제: 1234567890/YSR2000_20250101190000 (2025-01-01 19:00:00, 7250.50 MB)
2025-11-02 07:15:45 - INFO - 1개의 오래된 파일 삭제 완료
2025-11-02 07:15:45 - INFO - ================================================================================
2025-11-02 07:15:45 - INFO - 백업 완료
2025-11-02 07:15:45 - INFO - 업로드: 2개, 스킵: 1개, 오류: 0개
2025-11-02 07:15:45 - INFO - ================================================================================
```

---

## 🔄 업데이트 방법

### 개발자가 코드를 업데이트했을 때
운영 서버에서는 **자동으로 업데이트**됩니다!

1. 작업 스케줄러가 실행됨
2. `update_and_run.bat`가 자동으로 `git pull` 실행
3. 최신 `backup.exe`를 다운로드
4. 업데이트된 프로그램으로 백업 실행

**수동 업데이트**:
```bash
git pull
```

---

## 📞 지원

문제가 발생하면:
1. `backup.log` 파일 확인
2. 개발자에게 로그 파일 전달
3. 오류 메시지 스크린샷 전달

---

## 📝 변경 이력

### 2025-11-02
- 초기 버전 생성
- Kakao Cloud Object Storage 백업 기능 구현
- Windows 작업 스케줄러 자동 등록
- 단일 EXE 파일로 배포 (Python 불필요)
- Git 자동 업데이트 기능
- 대용량 파일 멀티파트 업로드
- 오래된 파일 자동 정리
- **원클릭 설치 스크립트 추가 (setup.bat)**
- **Git 자동 설치 기능 추가**

