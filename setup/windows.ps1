<#
Sherlock - Automation Discovery Setup for Windows
PaxIQ Consulting
#>

$ErrorActionPreference = "Stop"

$InstallDir = "$env:USERPROFILE\AutomationAudit"
$PipeDir = "$env:USERPROFILE\.screenpipe\pipes\sherlock"
$ScreenpipeUrl = "https://github.com/mediar-ai/screenpipe/releases/latest/download/screenpipe-x86_64-pc-windows-msvc.zip"
$PipeUrl = "https://raw.githubusercontent.com/PaxIQ/sherlock/main/pipe/pipe.md"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       Sherlock - Automation Discovery Agent (Windows)        ║" -ForegroundColor Cyan
Write-Host "║                     by PaxIQ Consulting                       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin for Unblock-File
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠ Running without admin privileges. Some features may be limited." -ForegroundColor Yellow
}

# Check if screenpipe is installed
$screenpipeCmd = $null
if (Get-Command screenpipe -ErrorAction SilentlyContinue) {
    Write-Host "✓ Screenpipe already installed" -ForegroundColor Green
    $screenpipeCmd = "screenpipe"
} else {
    Write-Host "→ Installing screenpipe..." -ForegroundColor Yellow
    
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Set-Location -Path $InstallDir
    
    try {
        Invoke-WebRequest -Uri $ScreenpipeUrl -OutFile "screenpipe.zip" -UseBasicParsing
    } catch {
        Write-Host "✗ Failed to download screenpipe. Check your internet connection." -ForegroundColor Red
        exit 1
    }
    
    Expand-Archive -Path "screenpipe.zip" -DestinationPath "." -Force
    Remove-Item "screenpipe.zip"
    
    # Unblock downloaded files (prevents SmartScreen warnings)
    Write-Host "→ Unblocking downloaded files..." -ForegroundColor Yellow
    Get-ChildItem -Path $InstallDir -Recurse | Unblock-File -ErrorAction SilentlyContinue
    
    $screenpipeCmd = "$InstallDir\screenpipe.exe"
    Write-Host "✓ Screenpipe installed to $InstallDir" -ForegroundColor Green
}

# Check if Ollama is installed
Write-Host ""
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Host "✓ Ollama already installed" -ForegroundColor Green
} else {
    Write-Host "→ Ollama not found." -ForegroundColor Yellow
    Write-Host "  Please install Ollama manually from: https://ollama.ai/download" -ForegroundColor Yellow
    Write-Host "  Then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Start-Process "https://ollama.ai/download"
    exit 1
}

# Pull the Gemma model
Write-Host ""
Write-Host "→ Pulling Gemma 3 4B model (this may take a few minutes on first run)..." -ForegroundColor Yellow
& ollama pull gemma3:4b

# Install the discovery pipe
Write-Host ""
Write-Host "→ Installing Sherlock discovery pipe..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $PipeDir | Out-Null

try {
    Invoke-WebRequest -Uri $PipeUrl -OutFile "$PipeDir\pipe.md" -UseBasicParsing
} catch {
    Write-Host "✗ Failed to download pipe. Using embedded version..." -ForegroundColor Yellow
    
    $PipeContent = @"
---
schedule: daily
enabled: true
provider: ollama
model: gemma3:4b
---

# Automation Discovery Agent

You are an expert RPA Consultant analyzing desktop activity to identify automation opportunities.

Query screenpipe for the last 24 hours. Find exactly 3 high-value automation opportunities:

1. **Data Entry Loops** - Copying from one app to another
2. **Repeated URL Visits** - Same portal, same clicks
3. **Standardized Responses** - Similar messages/emails

**EXCLUDE:** Personal apps, banking URLs, passwords, SSNs, API keys, credit cards.

Output to C:\Users\Public\Desktop\AUTOMATION_RECOMMENDATIONS.md with: Trigger, Action Steps, Time Saved, Recommended Architecture.
"@
    Set-Content -Path "$PipeDir\pipe.md" -Value $PipeContent
}

Write-Host "✓ Pipe installed to $PipeDir" -ForegroundColor Green

# Create uninstall script
$UninstallScript = @"
Write-Host "Uninstalling Sherlock..."

# Stop screenpipe if running
Get-Process -Name "screenpipe" -ErrorAction SilentlyContinue | Stop-Process -Force

# Remove installation
Remove-Item -Path "$env:USERPROFILE\AutomationAudit" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\.screenpipe\pipes\sherlock" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "✓ Sherlock uninstalled" -ForegroundColor Green
Write-Host "Note: Ollama and its models were not removed."
"@
Set-Content -Path "$InstallDir\uninstall.ps1" -Value $UninstallScript

# Start screenpipe if not running
Write-Host ""
$screenpipeProcess = Get-Process -Name "screenpipe" -ErrorAction SilentlyContinue
if ($screenpipeProcess) {
    Write-Host "✓ Screenpipe is already running" -ForegroundColor Green
} else {
    Write-Host "→ Starting screenpipe..." -ForegroundColor Yellow
    if ($screenpipeCmd) {
        Start-Process -FilePath $screenpipeCmd -ArgumentList "record" -WindowStyle Hidden
    } else {
        Start-Process -FilePath "screenpipe" -ArgumentList "record" -WindowStyle Hidden
    }
    Start-Sleep -Seconds 2
    $screenpipeProcess = Get-Process -Name "screenpipe" -ErrorAction SilentlyContinue
    if ($screenpipeProcess) {
        Write-Host "✓ Screenpipe started" -ForegroundColor Green
    } else {
        Write-Host "⚠ Screenpipe may not have started. Check Task Manager." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                     SETUP COMPLETE!                           ║" -ForegroundColor Green
Write-Host "╠═══════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  • Screenpipe is recording your screen activity               ║" -ForegroundColor White
Write-Host "║  • Analysis runs daily at 5:00 PM                             ║" -ForegroundColor White
Write-Host "║  • Reports saved to:                                          ║" -ForegroundColor White
Write-Host "║    C:\Users\Public\Desktop\AUTOMATION_RECOMMENDATIONS.md      ║" -ForegroundColor White
Write-Host "║                                                               ║" -ForegroundColor White
Write-Host "║  PERMISSIONS NOTE:                                            ║" -ForegroundColor White
Write-Host "║  Windows may prompt for permissions. Please allow them        ║" -ForegroundColor White
Write-Host "║  so the tool can properly analyze your workflows.             ║" -ForegroundColor White
Write-Host "║                                                               ║" -ForegroundColor White
Write-Host "║  To uninstall:                                                ║" -ForegroundColor White
Write-Host "║  & `"$InstallDir\uninstall.ps1`"                               ║" -ForegroundColor White
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
