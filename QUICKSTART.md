# 🚀 빠른 시작 가이드

**단 3분** 안에 백업 프로그램을 설치하고 실행하는 방법

---

## 📦 필요한 것

- ✅ Windows 10 이상
- ✅ 인터넷 연결
- ✅ **Git 자동 설치** (걱정 마세요!)
- ❌ Python **불필요**

---

## 🔥 원클릭 설치 (가장 쉬운 방법!)

### 1️⃣ setup.bat 다운로드
```
https://github.com/dev-sean-2016/medi101-backup
→ setup.bat 파일 다운로드
```

### 2️⃣ 관리자 권한으로 실행
```
setup.bat 마우스 오른쪽 클릭
→ "관리자 권한으로 실행"
```

### 3️⃣ 화면 안내에 따라 진행
```
- Git 자동 설치 (없는 경우)
- 백업 프로그램 다운로드
- config.json 파일 수정 (Access Key, Secret Key 입력)
- 작업 스케줄러 등록
```

---

## ✅ 완료!

매일 오전 7시에 자동으로 백업됩니다.

**결과 확인**: `C:\medi101-backup\backup.log` 파일 열기

---

## 📝 수동 설치 (원클릭이 실패하는 경우)

### 1️⃣ Git 설치
```
install_git.bat 더블클릭
(Git이 자동으로 설치됨)
```

### 2️⃣ 설정 파일 생성
```
1. config.json.template 파일을 복사
2. 이름을 config.json으로 변경
3. 메모장으로 열어서 아래 값 입력:
   - access_key: Kakao Cloud Access Key
   - secret_key: Kakao Cloud Secret Key
   - business_number: 사업자 번호
   - source_paths: 백업할 폴더 경로
```

### 3️⃣ 테스트 실행
```
update_and_run.bat 더블클릭
```

### 4️⃣ 자동 실행 설정
```
setup_scheduler.bat 마우스 오른쪽 버튼 클릭
→ "관리자 권한으로 실행" 선택
```

---

## ✅ 완료!

매일 오전 7시에 자동으로 백업됩니다.

**결과 확인**: `backup.log` 파일 열기

---

## 🆘 문제 발생시

### backup.exe가 없다고 나와요
→ 개발자에게 문의 (EXE 빌드 필요)

### config.json이 없다고 나와요
→ config.json.template을 config.json으로 복사하고 값 입력

### 백업이 안 돼요
→ backup.log 파일을 열어서 오류 확인

---

**자세한 설명**: [README.md](README.md) 참고

