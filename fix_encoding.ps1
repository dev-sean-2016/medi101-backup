# ====================================================================
# BAT 파일 인코딩 수정 스크립트 (UTF-8 BOM으로 변환)
# 
# Windows에서 한글이 깨지는 BAT 파일을 UTF-8 BOM으로 변환합니다.
# 
# 사용 방법:
#   PowerShell에서 실행:
#   .\fix_encoding.ps1
# ====================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BAT 파일 인코딩 수정 중..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 현재 디렉토리의 모든 BAT 파일 찾기
$batFiles = Get-ChildItem -Filter "*.bat" -File

if ($batFiles.Count -eq 0) {
    Write-Host "[알림] BAT 파일이 없습니다." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "계속하려면 Enter 키를 누르세요"
    exit
}

Write-Host "발견된 BAT 파일: $($batFiles.Count)개" -ForegroundColor Green
Write-Host ""

$successCount = 0
$errorCount = 0

foreach ($file in $batFiles) {
    try {
        Write-Host "처리 중: $($file.Name)... " -NoNewline
        
        # 파일 내용을 UTF-8로 읽기
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # UTF-8 BOM으로 저장
        $utf8BOM = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($file.FullName, $content, $utf8BOM)
        
        Write-Host "[OK]" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "[실패]" -ForegroundColor Red
        Write-Host "  오류: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "완료!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "성공: $successCount 개" -ForegroundColor Green
Write-Host "실패: $errorCount 개" -ForegroundColor Red
Write-Host ""
Write-Host "이제 BAT 파일을 실행하면 한글이 정상적으로 표시됩니다." -ForegroundColor Cyan
Write-Host ""

Read-Host "계속하려면 Enter 키를 누르세요"

