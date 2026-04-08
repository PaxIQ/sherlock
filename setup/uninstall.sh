#!/bin/bash
# Sherlock - Uninstaller for macOS and Linux
# PaxIQ

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         Sherlock - Uninstaller (macOS / Linux)                ║"
echo "║                        by PaxIQ                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Stop screenpipe if running
echo "→ Stopping screenpipe..."
pkill -f screenpipe 2>/dev/null && echo "✓ Screenpipe stopped" || echo "  (Screenpipe was not running)"

# Remove installation directory (binary)
echo "→ Removing installation files..."
INSTALL_DIR="$HOME/.automation_audit"
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "✓ Removed $INSTALL_DIR"
else
    echo "  (Installation directory not found — skipping)"
fi

# Remove Sherlock pipe
echo "→ Removing Sherlock pipe..."
PIPE_DIR="$HOME/.screenpipe/pipes/sherlock"
if [ -d "$PIPE_DIR" ]; then
    rm -rf "$PIPE_DIR"
    echo "✓ Removed Sherlock pipe"
else
    echo "  (Pipe directory not found — skipping)"
fi

# Optionally remove all screenpipe data
DATA_DIR="$HOME/.screenpipe"
if [ -d "$DATA_DIR" ]; then
    echo ""
    read -rp "  Remove ALL screenpipe data at $DATA_DIR? This deletes all recordings. (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        rm -rf "$DATA_DIR"
        echo "✓ Removed screenpipe data"
    else
        echo "  Screenpipe data kept at $DATA_DIR"
    fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   UNINSTALL COMPLETE!                         ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  Sherlock has been removed.                                   ║"
echo "║                                                               ║"
echo "║  Note: Ollama and its models were NOT removed.                ║"

if [[ "$OSTYPE" == "darwin"* ]]; then
echo "║  To remove Ollama: brew uninstall ollama                      ║"
else
echo "║  To remove Ollama: check your package manager or ollama.ai    ║"
fi

echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
read -rp "Press Enter to exit..."
