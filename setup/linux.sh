#!/bin/bash
# Sherlock - Automation Discovery Setup for Linux
# PaxIQ

set -e

INSTALL_DIR="$HOME/.automation_audit"
PIPE_DIR="$HOME/.screenpipe/pipes/sherlock"
SCREENPIPE_URL="https://github.com/screenpipe/screenpipe/releases/download/cli-latest/screenpipe-0.3.264-x86_64-unknown-linux-gnu.tar.gz"
PIPE_URL="https://raw.githubusercontent.com/PaxIQ/sherlock/main/pipe/pipe.md"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║       Sherlock - Automation Discovery Agent (Linux)          ║"
echo "║                           by PaxIQ                            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check if screenpipe is already installed
if command -v screenpipe &> /dev/null; then
    echo "✓ Screenpipe already installed"
    SCREENPIPE_CMD="screenpipe"
elif [ -f "$INSTALL_DIR/screenpipe" ]; then
    echo "✓ Screenpipe already installed"
    SCREENPIPE_CMD="$INSTALL_DIR/screenpipe"
else
    echo "→ Installing screenpipe..."
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || exit 1
    
    if ! curl -fSL "$SCREENPIPE_URL" -o screenpipe.tar.gz; then
        echo "✗ Failed to download screenpipe. Check your internet connection."
        exit 1
    fi
    
    tar -xzf screenpipe.tar.gz
    rm screenpipe.tar.gz
    
    chmod +x ./screenpipe
    SCREENPIPE_CMD="$INSTALL_DIR/screenpipe"
    echo "✓ Screenpipe installed to $INSTALL_DIR"
fi

# Check if Ollama is installed
echo ""
if command -v ollama &> /dev/null; then
    echo "✓ Ollama already installed"
else
    echo "→ Ollama not found. Installing..."
    curl -fsSL https://ollama.ai/install.sh | sh
fi

# Pull the Gemma model
echo ""
echo "→ Pulling Gemma 3 4B model (this may take a few minutes on first run)..."
ollama pull gemma3:4b

# Install the discovery pipe
echo ""
echo "→ Installing Sherlock discovery pipe..."
mkdir -p "$PIPE_DIR"

if ! curl -fsSL "$PIPE_URL" -o "$PIPE_DIR/pipe.md"; then
    echo "✗ Failed to download pipe. Using embedded version..."
    cat << 'PIPE_EOF' > "$PIPE_DIR/pipe.md"
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

Output to ~/Desktop/AUTOMATION_RECOMMENDATIONS.md with: Trigger, Action Steps, Time Saved, Recommended Architecture.
PIPE_EOF
fi

echo "✓ Pipe installed to $PIPE_DIR"

# Create uninstall script
cat << 'UNINSTALL_EOF' > "$INSTALL_DIR/uninstall.sh"
#!/bin/bash
echo "Uninstalling Sherlock..."

# Stop screenpipe if running
pkill -f screenpipe 2>/dev/null || true

# Remove installation
rm -rf "$HOME/.automation_audit"
rm -rf "$HOME/.screenpipe/pipes/sherlock"

echo "✓ Sherlock uninstalled"
echo "Note: Ollama and its models were not removed."
UNINSTALL_EOF
chmod +x "$INSTALL_DIR/uninstall.sh"

# Start screenpipe if not running
echo ""
if pgrep -f "screenpipe" > /dev/null; then
    echo "✓ Screenpipe is already running"
else
    echo "→ Starting screenpipe..."
    nohup $SCREENPIPE_CMD record > "$INSTALL_DIR/screenpipe.log" 2>&1 &
    sleep 2
    if pgrep -f "screenpipe" > /dev/null; then
        echo "✓ Screenpipe started"
    else
        echo "⚠ Screenpipe may not have started. Check $INSTALL_DIR/screenpipe.log"
    fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                     SETUP COMPLETE!                           ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  • Screenpipe is recording your screen activity               ║"
echo "║  • Analysis runs daily at 5:00 PM                             ║"
echo "║  • Reports saved to: ~/Desktop/AUTOMATION_RECOMMENDATIONS.md  ║"
echo "║                                                               ║"
echo "║  PERMISSIONS NOTE:                                            ║"
echo "║  Depending on your desktop environment (Wayland/X11), you     ║"
echo "║  may need to grant screen recording permissions via your      ║"
echo "║  system settings or xdg-desktop-portal.                       ║"
echo "║                                                               ║"
echo "║  To uninstall: ~/.automation_audit/uninstall.sh               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
