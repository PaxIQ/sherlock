# Sherlock

**Automation Discovery Agent** — Surfaces automation opportunities from client screen activity using screenpipe and local AI.

## How It Works

1. Client runs a one-line setup script for their OS
2. Screenpipe records screen activity locally (all data stays on their machine)
3. A scheduled pipe analyzes activity daily using local LLM (Gemma 3 4B)
4. Client reviews the generated report and manually emails it to PaxIQ

**Privacy by design:** No data ever leaves the client's machine except the summary report they choose to share.

## Quick Start

### macOS
```bash
curl -sSL https://raw.githubusercontent.com/PaxIQ/sherlock/main/setup/macos.sh | bash
```

### Windows (PowerShell as Admin)
```powershell
iwr -useb https://raw.githubusercontent.com/PaxIQ/sherlock/main/setup/windows.ps1 | iex
```

### Linux
```bash
curl -sSL https://raw.githubusercontent.com/PaxIQ/sherlock/main/setup/linux.sh | bash
```

## What Gets Analyzed

The discovery pipe looks for three patterns:

1. **Data Entry Loops** — Copying from one app and pasting into another
2. **Repeated URL Visits** — Same internal portal, same click sequence
3. **Standardized Responses** — Similar emails/messages triggered by keywords

## Privacy Exclusions

The local LLM is instructed to ignore:
- Personal apps (Spotify, Apple Music, etc.)
- Banking/financial URLs
- Content containing: password, SSN, confidential, credit card patterns, API keys

## Output

A markdown file is saved to the client's Desktop:
- **macOS/Linux:** `~/Desktop/AUTOMATION_RECOMMENDATIONS.md`
- **Windows:** `C:\Users\Public\Desktop\AUTOMATION_RECOMMENDATIONS.md`

The client reviews this file and sends it to PaxIQ at their discretion.

## Requirements

- **Node.js** (v18+) — required for screenpipe
- 8 GB RAM minimum
- ~5-10 GB disk space per month
- macOS, Windows 10/11, or Linux with X11/Wayland
- Internet connection for initial setup only

## Uninstall

### macOS/Linux
```bash
~/.automation_audit/uninstall.sh
```

### Windows
```powershell
& "$env:USERPROFILE\AutomationAudit\uninstall.ps1"
```

## License

MIT
