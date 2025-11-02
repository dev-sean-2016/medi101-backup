# 📊 워크플로우 및 역할 분리

이 문서는 **개발자**와 **운영자**의 역할을 명확히 구분하고, 각각의 작업 흐름을 설명합니다.

---

## 👨‍💻 개발자 워크플로우

### 초기 설정 (최초 1회)

```bash
# 1. Git 저장소 생성
git init
git remote add origin [저장소 URL]

# 2. Python 가상환경 생성 (선택사항)
python -m venv venv
venv\Scripts\activate  # Windows

# 3. 패키지 설치
pip install -r requirements.txt

# 4. 테스트용 config.json 생성
copy config.json.template config.json
notepad config.json  # 테스트용 값 입력
```

### 개발 사이클

```bash
# 1. 코드 수정
#    backup.py 파일 수정

# 2. 로컬 테스트
python backup.py

# 3. 로그 확인
type backup.log

# 4. EXE 빌드
build_exe.bat

# 5. EXE 테스트
backup.exe

# 6. Git 커밋
git add backup.py backup.exe
git commit -m "기능 추가: XXXX"
git push origin main
```

### 개발자가 사용하는 파일

| 파일 | 용도 |
|------|------|
| `backup.py` | 소스 코드 (수정) |
| `build_exe.bat` | EXE 빌드 |
| `requirements.txt` | Python 패키지 관리 |
| `config.json` | 로컬 테스트용 (Git 제외) |

### 개발자가 Git에 커밋하는 파일

✅ 커밋 **해야 하는** 파일:
- `backup.py` (소스 코드)
- `backup.exe` (빌드된 실행 파일)
- `config.json.template` (설정 템플릿)
- `requirements.txt`
- `.gitignore`
- `README.md`, `QUICKSTART.md`, `WORKFLOW.md`
- `*.bat` (모든 배치 스크립트)

❌ 커밋 **하면 안 되는** 파일:
- `config.json` (민감 정보 포함)
- `backup.log` (실행 로그)
- `build/`, `dist/` (빌드 임시 폴더)
- `__pycache__/` (Python 캐시)

---

## 👨‍🔧 운영자 워크플로우

### 초기 설치 (최초 1회)

```bash
# 1. Git 설치 (없는 경우)
install_git.bat 실행

# 2. 저장소 클론
cd C:\원하는경로
git clone [저장소 URL] s3cp
cd s3cp

# 3. 설정 파일 생성
copy config.json.template config.json
notepad config.json  # 실제 값 입력

# 4. 테스트 실행
update_and_run.bat

# 5. 작업 스케줄러 등록 (관리자 권한)
setup_scheduler.bat (마우스 오른쪽 클릭 → 관리자 권한으로 실행)
```

### 일상적 운영

**자동 실행** (설정 후):
- 매일 오전 7시에 자동 실행
- Git pull → backup.exe 실행
- 결과는 backup.log에 저장

**수동 실행** (필요시):
```bash
update_and_run.bat 더블클릭
```

**로그 확인**:
```bash
notepad backup.log
```

### 업데이트 (개발자가 코드 수정 시)

**자동 업데이트** (권장):
- 작업 스케줄러가 실행될 때 자동으로 `git pull` 실행
- 최신 `backup.exe` 다운로드
- 아무 작업 불필요 ✅

**수동 업데이트**:
```bash
git pull
```

### 운영자가 사용하는 파일

| 파일 | 용도 |
|------|------|
| `backup.exe` | 백업 실행 (Git에서 자동 업데이트) |
| `config.json` | 설정 파일 (직접 생성, Git 제외) |
| `backup.log` | 실행 로그 (자동 생성) |
| `update_and_run.bat` | Git pull + 백업 실행 |
| `setup_scheduler.bat` | 작업 스케줄러 등록 |

---

## 🔄 자동 업데이트 프로세스

### 개발자가 코드 수정

```
개발자 PC:
1. backup.py 수정
2. build_exe.bat 실행 → backup.exe 생성
3. Git commit & push
```

### 운영 서버에 자동 반영

```
운영 서버 (작업 스케줄러 실행 시):
1. update_and_run.bat 실행
2. git pull (최신 backup.exe 다운로드)
3. backup.exe 실행 (업데이트된 버전)
```

**결과**: 운영자는 아무 작업 없이 자동으로 최신 버전 사용 ✅

---

## 📁 파일 역할 정리

### Git 저장소 구조

```
s3cp/
├── 📄 backup.py                  [개발자] 소스 코드
├── 📦 backup.exe                 [개발자→운영자] 실행 파일
├── 📝 config.json.template       [개발자] 설정 템플릿
├── 📋 requirements.txt           [개발자] Python 패키지
├── 🚫 .gitignore                 [개발자] Git 제외 목록
│
├── 📖 README.md                  [문서] 전체 설명서
├── 🚀 QUICKSTART.md              [문서] 빠른 시작
├── 📊 WORKFLOW.md                [문서] 이 파일
│
├── 🔨 build_exe.bat              [개발자] EXE 빌드
├── 🔄 update_and_run.bat         [운영자] Git pull + 실행
├── ⏰ setup_scheduler.bat        [운영자] 작업 스케줄러 등록
├── ❌ remove_scheduler.bat       [운영자] 작업 스케줄러 제거
└── 📥 install_git.bat            [운영자] Git 설치 확인
```

### 로컬 전용 파일 (Git 제외)

```
s3cp/
├── 🔐 config.json                [운영자] 실제 설정 (민감 정보)
├── 📋 backup.log                 [자동생성] 실행 로그
├── 📂 build/                     [개발자] 빌드 임시 폴더
├── 📂 dist/                      [개발자] 빌드 결과 폴더
└── 📂 __pycache__/               [개발자] Python 캐시
```

---

## 🔐 보안 고려사항

### 민감한 정보 관리

**config.json** (절대 Git에 커밋하지 마세요):
- Kakao Cloud Access Key
- Kakao Cloud Secret Key
- 사업자 번호

**확인 방법**:
```bash
# config.json이 Git 추적 대상인지 확인
git status

# config.json이 나타나면 안 됨 (이미 .gitignore에 포함됨)
```

### Git 저장소 권한

- **Public 저장소**: backup.exe는 공개되지만 config.json은 제외되므로 안전
- **Private 저장소** (권장): 팀 내부에서만 접근 가능

---

## 🧪 테스트 시나리오

### 개발자 테스트

```bash
# 1. 소스 코드 테스트
python backup.py

# 2. EXE 빌드 테스트
build_exe.bat

# 3. EXE 실행 테스트
backup.exe

# 4. 로그 확인
type backup.log
```

### 운영자 테스트

```bash
# 1. 수동 실행 테스트
update_and_run.bat

# 2. 작업 스케줄러 수동 실행
schtasks /run /tn "KakaoCloudBackup"

# 3. 로그 확인
notepad backup.log
```

---

## 🐛 문제 해결 프로세스

### 1단계: 로그 확인
```bash
notepad backup.log
```

### 2단계: 수동 실행으로 재현
```bash
backup.exe
```

### 3단계: 개발자에게 전달
- `backup.log` 파일 전체
- 오류 메시지 스크린샷
- `config.json`의 민감하지 않은 부분 (경로, 서비스명 등)

---

## 📞 역할별 연락 사항

### 운영자 → 개발자 연락이 필요한 경우

1. ❌ backup.exe 파일이 없음
2. ❌ 백업 로직 오류 (backup.log에 오류)
3. ❌ 새로운 기능 요청

### 개발자 → 운영자 전달 사항

1. ✅ 새 버전 배포 완료 (자동 업데이트)
2. ⚠️ 설정 파일 변경 필요 (config.json 수정 요청)
3. ⚠️ 작업 스케줄러 재등록 필요

---

## ✅ 체크리스트

### 개발자 배포 체크리스트

- [ ] backup.py 수정 완료
- [ ] 로컬 테스트 완료 (`python backup.py`)
- [ ] EXE 빌드 완료 (`build_exe.bat`)
- [ ] EXE 테스트 완료 (`backup.exe`)
- [ ] Git 커밋 (`git add backup.py backup.exe`)
- [ ] Git 푸시 (`git push origin main`)
- [ ] 운영자에게 업데이트 알림 (선택사항)

### 운영자 설치 체크리스트

- [ ] Git 설치 완료
- [ ] 저장소 클론 완료
- [ ] config.json 생성 및 값 입력 완료
- [ ] 수동 실행 테스트 완료 (`update_and_run.bat`)
- [ ] backup.log 확인 (오류 없음)
- [ ] 작업 스케줄러 등록 완료 (`setup_scheduler.bat`)
- [ ] 작업 스케줄러 확인 (작업 스케줄러 프로그램에서 확인)
- [ ] 다음날 백업 로그 확인

---

**이 문서의 최종 수정일**: 2025-11-02

