<#
Sherlock - Automation Discovery Setup for Windows
PaxIQ
#>

$ErrorActionPreference = "Stop"

$InstallDir = "$env:USERPROFILE\AutomationAudit"
$PipeDir = "$env:USERPROFILE\.screenpipe\pipes\sherlock"
$PipeUrl = "https://raw.githubusercontent.com/PaxIQ/sherlock/main/pipe/pipe.md"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   Sherlock - Automation Discovery Agent (Windows) by PaxIQ   " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin for Unblock-File
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Running without admin privileges. Some features may be limited." -ForegroundColor Yellow
}

# Install screenpipe from npm registry (no Node.js required)
$screenpipeCmd = $null
if (Get-Command screenpipe -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Screenpipe already installed" -ForegroundColor Green
    $screenpipeCmd = "screenpipe"
} elseif (Test-Path "$InstallDir\screenpipe.exe") {
    Write-Host "[OK] Screenpipe already installed" -ForegroundColor Green
    $screenpipeCmd = "$InstallDir\screenpipe.exe"
} else {
    Write-Host "[ ] Installing screenpipe..." -ForegroundColor Yellow

    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

    # Resolve latest version from npm registry
    try {
        $npmMeta = Invoke-RestMethod -Uri "https://registry.npmjs.org/screenpipe/latest" -UseBasicParsing
        $screenpipeVersion = $npmMeta.version
    } catch {
        Write-Host "[X] Could not resolve screenpipe version. Check your internet connection." -ForegroundColor Red
        exit 1
    }
    Write-Host "[ ] Latest version: $screenpipeVersion" -ForegroundColor Yellow

    $tarballUrl = "https://registry.npmjs.org/@screenpipe/cli-win32-x64/-/cli-win32-x64-${screenpipeVersion}.tgz"
    $tgzPath = "$env:TEMP\screenpipe.tgz"

    try {
        Invoke-WebRequest -Uri $tarballUrl -OutFile $tgzPath -UseBasicParsing
    } catch {
        Write-Host "[X] Failed to download screenpipe. Check your internet connection." -ForegroundColor Red
        exit 1
    }

    # tar is available on Windows 10+ (build 17063+)
    $extractDir = "$env:TEMP\screenpipe_extract"
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    & tar -xzf $tgzPath -C $extractDir
    # Copy all files from bin\ (exe + required DLLs)
    Get-ChildItem -Path "$extractDir\package\bin\*" | Move-Item -Destination $InstallDir -Force
    Remove-Item -Path $tgzPath, $extractDir -Recurse -Force -ErrorAction SilentlyContinue

    # Unblock all extracted files (prevents SmartScreen warnings)
    Get-ChildItem -Path $InstallDir | Unblock-File -ErrorAction SilentlyContinue

    $screenpipeCmd = "$InstallDir\screenpipe.exe"
    Write-Host "[OK] Screenpipe $screenpipeVersion installed to $InstallDir" -ForegroundColor Green
}

# Check if Ollama is installed
Write-Host ""
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Ollama already installed" -ForegroundColor Green
} else {
    Write-Host "[!] Ollama not found." -ForegroundColor Yellow
    Write-Host "    Please install Ollama from: https://ollama.ai/download" -ForegroundColor Yellow
    Write-Host "    Then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Start-Process "https://ollama.ai/download"
    exit 1
}

# Pull the Gemma model via Ollama REST API (avoids triggering the Ollama desktop UI)
Write-Host ""
Write-Host "[ ] Pulling Gemma 3 4B model (this may take a few minutes on first run)..." -ForegroundColor Yellow
$ollamaBody = '{"name":"gemma3:4b"}'
try {
    Invoke-RestMethod -Uri "http://localhost:11434/api/pull" -Method Post -Body $ollamaBody -ContentType "application/json" -TimeoutSec 600 | Out-Null
    Write-Host "[OK] Gemma 3 4B ready" -ForegroundColor Green
} catch {
    Write-Host "    (API not ready, falling back to CLI...)" -ForegroundColor Yellow
    & ollama pull gemma3:4b
}

# Install the discovery pipe
Write-Host ""
Write-Host "[ ] Installing Sherlock discovery pipe..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $PipeDir | Out-Null

try {
    Invoke-WebRequest -Uri $PipeUrl -OutFile "$PipeDir\pipe.md" -UseBasicParsing
} catch {
    Write-Host "[!] Failed to download pipe. Using embedded version..." -ForegroundColor Yellow

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

Append a new dated section to C:\Users\Public\Desktop\AUTOMATION_RECOMMENDATIONS.md (create if it doesn't exist). Never overwrite previous entries. Format each entry with: Report date, Trigger, Action Steps, Time Saved, Recommended Architecture.
"@
    Set-Content -Path "$PipeDir\pipe.md" -Value $PipeContent
}

Write-Host "[OK] Pipe installed to $PipeDir" -ForegroundColor Green

# Start screenpipe if not running
Write-Host ""
$screenpipeProcess = Get-Process -Name "screenpipe" -ErrorAction SilentlyContinue
if ($screenpipeProcess) {
    Write-Host "[OK] Screenpipe is already running" -ForegroundColor Green
} else {
    Write-Host "[ ] Starting screenpipe..." -ForegroundColor Yellow
    Start-Process -FilePath $screenpipeCmd -ArgumentList "record" -WindowStyle Minimized
    Start-Sleep -Seconds 3
    $screenpipeProcess = Get-Process -Name "screenpipe" -ErrorAction SilentlyContinue
    if ($screenpipeProcess) {
        Write-Host "[OK] Screenpipe started" -ForegroundColor Green
    } else {
        Write-Host "[!] Screenpipe may not have started. Check Task Manager." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "                       SETUP COMPLETE!                         " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Screenpipe is recording your screen activity" -ForegroundColor White
Write-Host "  Analysis runs daily at 8:00 PM" -ForegroundColor White
Write-Host "  Reports saved to:" -ForegroundColor White
Write-Host "    C:\Users\Public\Desktop\AUTOMATION_RECOMMENDATIONS.md" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "  PERMISSIONS NOTE:" -ForegroundColor White
Write-Host "  Windows may prompt for permissions. Please allow them" -ForegroundColor White
Write-Host "  so the tool can properly analyze your workflows." -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
