# Script PowerShell para executar testes com cobertura
# Uso: .\scripts\run_coverage.ps1

Write-Host "=== Executando testes com cobertura ===" -ForegroundColor Cyan
flutter test --coverage

if ($LASTEXITCODE -ne 0) {
    Write-Host "FALHA: Testes falharam." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Resumo da cobertura ===" -ForegroundColor Cyan

$lcovFile = "coverage/lcov.info"
if (Test-Path $lcovFile) {
    $content = Get-Content $lcovFile
    $totalLines = 0
    $coveredLines = 0
    $files = @()

    foreach ($line in $content) {
        if ($line -match "^SF:(.+)") {
            $files += $Matches[1]
        }
        if ($line -match "^DA:(\d+),(\d+)") {
            $totalLines++
            if ([int]$Matches[2] -gt 0) {
                $coveredLines++
            }
        }
    }

    if ($totalLines -gt 0) {
        $percent = [math]::Round(($coveredLines / $totalLines) * 100, 1)
        Write-Host "Linhas instrumentadas: $totalLines"
        Write-Host "Linhas cobertas:       $coveredLines"
        Write-Host "Cobertura total:       $percent%" -ForegroundColor $(if ($percent -ge 70) { "Green" } elseif ($percent -ge 50) { "Yellow" } else { "Red" })
    }

    Write-Host ""
    Write-Host "=== Arquivos cobertos ===" -ForegroundColor Cyan
    $files | Sort-Object | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "Arquivo $lcovFile não encontrado." -ForegroundColor Red
}

Write-Host ""
Write-Host "Para gerar relatório HTML, instale lcov e execute:" -ForegroundColor DarkGray
Write-Host "  genhtml coverage/lcov.info -o coverage/html" -ForegroundColor DarkGray
