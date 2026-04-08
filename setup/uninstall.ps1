<#
Sherlock - Uninstaller for Windows
PaxIQ
#>

$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "         Sherlock - Uninstaller (Windows) by PaxIQ             " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Stop screenpipe if running
Write-Host "[ ] Stopping screenpipe..." -ForegroundColor Yellow
Get-Process -Name "screenpipe" | Stop-Process -Force
Start-Sleep -Seconds 1
Write-Host "[OK] Screenpipe stopped" -ForegroundColor Green

# Remove installation directory (binary + DLLs)
Write-Host "[ ] Removing installation files..." -ForegroundColor Yellow
$InstallDir = "$env:USERPROFILE\AutomationAudit"
if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
    Write-Host "[OK] Removed $InstallDir" -ForegroundColor Green
} else {
    Write-Host "    (Installation directory not found -- skipping)" -ForegroundColor Gray
}

# Remove Sherlock pipe
Write-Host "[ ] Removing Sherlock pipe..." -ForegroundColor Yellow
$PipeDir = "$env:USERPROFILE\.screenpipe\pipes\sherlock"
if (Test-Path $PipeDir) {
    Remove-Item -Path $PipeDir -Recurse -Force
    Write-Host "[OK] Removed Sherlock pipe" -ForegroundColor Green
} else {
    Write-Host "    (Pipe directory not found -- skipping)" -ForegroundColor Gray
}

# Optionally remove all screenpipe data
$DataDir = "$env:USERPROFILE\.screenpipe"
if (Test-Path $DataDir) {
    Write-Host ""
    $confirm = Read-Host "Remove ALL screenpipe data at $DataDir? This deletes all recordings. (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Remove-Item -Path $DataDir -Recurse -Force
        Write-Host "[OK] Removed screenpipe data" -ForegroundColor Green
    } else {
        Write-Host "    Screenpipe data kept at $DataDir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "                    UNINSTALL COMPLETE!                        " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Sherlock has been removed." -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "  Note: Ollama and its models were NOT removed." -ForegroundColor White
Write-Host "  To remove Ollama, use Windows Settings > Apps" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
