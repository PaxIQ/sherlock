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

## Privacy & Data Filtering

Sherlock applies privacy protection at **two distinct layers**:

### Layer 1 — Capture exclusions (before data is stored)

These apps and URLs are never recorded in the first place. The full list is maintained in [`config/privacy.yml`](config/privacy.yml).

| Category | Examples |
|----------|---------|
| Password managers | 1Password, Bitwarden, LastPass, Dashlane, KeePass, Keeper, NordPass |
| Banking & finance | Chase, BofA, Wells Fargo, Citi, Capital One, Fidelity, Schwab, PayPal, Venmo, Coinbase |
| Healthcare | MyChart, Epic, CVS, Walgreens |
| Tax & finance tools | TurboTax, H&R Block, Mint, YNAB |
| Entertainment | Spotify, Netflix, Apple Music, Hulu, Disney+ |
| Personal communication | Signal, WhatsApp, Telegram, FaceTime |
| Private browsing | All incognito/private browser windows |

In addition, screenpipe's built-in PII removal is enabled, which redacts SSNs, credit card numbers, and similar patterns from audio transcriptions before storage.

### Data retention

Sherlock configures screenpipe to **automatically delete all data older than 7 days** — screenshots, OCR text, and audio transcriptions. This limits how much historical data sits on the client's machine at any given time.

### Layer 2 — Report exclusions (before the summary is written)

Even if something slips through capture, the AI agent is instructed not to include findings involving:
- Passwords, API keys, bearer tokens
- SSNs, credit card patterns, healthcare data
- Personal apps, banking URLs, confidential-marked content

### What this means in practice

The raw SQLite database (`~/.screenpipe/db.sqlite`) contains everything that wasn't excluded at Layer 1. Only the client has access to this file — it never leaves their machine. The summary report they share with PaxIQ is filtered at both layers.

## Output

A markdown file is saved to the client's Desktop:
- **macOS/Linux:** `~/Desktop/AUTOMATION_RECOMMENDATIONS.md`
- **Windows:** `C:\Users\Public\Desktop\AUTOMATION_RECOMMENDATIONS.md`

The client reviews this file and sends it to PaxIQ at their discretion.

## Requirements

- 8 GB RAM minimum
- ~5-10 GB disk space per month
- macOS, Windows 10+ (build 17063+), or Linux with X11/Wayland
- Internet connection for initial setup only
- No other software required — screenpipe binary is downloaded automatically

## Uninstall

### macOS
```bash
curl -sSL https://raw.githubusercontent.com/PaxIQ/sherlock/main/setup/uninstall.sh | bash
```

### Windows (PowerShell)
```powershell
iwr -useb https://raw.githubusercontent.com/PaxIQ/sherlock/main/setup/uninstall.ps1 | iex
```

### Linux
```bash
curl -sSL https://raw.githubusercontent.com/PaxIQ/sherlock/main/setup/uninstall.sh | bash
```

## License

MIT
