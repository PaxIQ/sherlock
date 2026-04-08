<#
Sherlock - Uninstaller for Windows
PaxIQ
#>

$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Sherlock - Uninstaller (Windows)                      ║" -ForegroundColor Cyan
Write-Host "║                        by PaxIQ                               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Stop screenpipe if running
Write-Host "→ Stopping screenpipe..." -ForegroundColor Yellow
Get-Process -Name "screenpipe" | Stop-Process -Force
Start-Sleep -Seconds 1
Write-Host "✓ Screenpipe stopped" -ForegroundColor Green

# Remove installation directory (binary + DLLs)
Write-Host "→ Removing installation files..." -ForegroundColor Yellow
$InstallDir = "$env:USERPROFILE\AutomationAudit"
if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
    Write-Host "✓ Removed $InstallDir" -ForegroundColor Green
} else {
    Write-Host "  (Installation directory not found — skipping)" -ForegroundColor Gray
}

# Remove screenpipe data and pipe
Write-Host "→ Removing screenpipe data and Sherlock pipe..." -ForegroundColor Yellow
$PipeDir = "$env:USERPROFILE\.screenpipe\pipes\sherlock"
if (Test-Path $PipeDir) {
    Remove-Item -Path $PipeDir -Recurse -Force
    Write-Host "✓ Removed Sherlock pipe" -ForegroundColor Green
}

$DataDir = "$env:USERPROFILE\.screenpipe"
if (Test-Path $DataDir) {
    $confirm = Read-Host "  Remove ALL screenpipe data at $DataDir? This deletes all recordings. (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Remove-Item -Path $DataDir -Recurse -Force
        Write-Host "✓ Removed screenpipe data" -ForegroundColor Green
    } else {
        Write-Host "  Screenpipe data kept at $DataDir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                   UNINSTALL COMPLETE!                         ║" -ForegroundColor Green
Write-Host "╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Sherlock has been removed.                                   ║" -ForegroundColor White
Write-Host "║                                                               ║" -ForegroundColor White
Write-Host "║  Note: Ollama and its models were NOT removed.                ║" -ForegroundColor White
Write-Host "║  To remove Ollama, use Windows Settings > Add/Remove Programs ║" -ForegroundColor White
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
