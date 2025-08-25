#!/bin/bash

# Augment Monitor Cron Job Installation Script
# This script sets up automatic monitoring for Augment extension updates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_PATH=$(which node)
CURSOR_PATH=$(which cursor)
CRON_SCHEDULE="0 */6 * * *"  # Every 6 hours

echo "🚀 Installing Augment Monitor Cron Job..."
echo "Script directory: $SCRIPT_DIR"
echo "Node.js path: $NODE_PATH"
echo "Cursor path: $CURSOR_PATH"
echo "Schedule: $CRON_SCHEDULE"

# Check if node is available
if [ ! -f "$NODE_PATH" ]; then
    echo "❌ Error: Node.js not found. Please install Node.js first."
    exit 1
fi

# Check if at least one supported IDE is available
CURSOR_AVAILABLE=false
VSCODE_AVAILABLE=false

if [ -f "$CURSOR_PATH" ]; then
    CURSOR_AVAILABLE=true
    echo "✓ Cursor found at: $CURSOR_PATH"
fi

VSCODE_PATH=$(which code 2>/dev/null || echo "")
if [ -n "$VSCODE_PATH" ]; then
    VSCODE_AVAILABLE=true
    echo "✓ VS Code found at: $VSCODE_PATH"
fi

if [ "$CURSOR_AVAILABLE" = false ] && [ "$VSCODE_AVAILABLE" = false ]; then
    echo "❌ Error: No supported IDE found (Cursor or VS Code)"
    echo "   Please install Cursor or VS Code first."
    exit 1
fi

# Check if the main script exists
if [ ! -f "$SCRIPT_DIR/index.js" ]; then
    echo "❌ Error: index.js not found in $SCRIPT_DIR"
    exit 1
fi

# Make the script executable
chmod +x "$SCRIPT_DIR/index.js"

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"

# Set up environment variables for cron
ENV_SETUP="PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
if [ "$CURSOR_AVAILABLE" = true ]; then
    ENV_SETUP="$ENV_SETUP\nCURSOR_PATH=$CURSOR_PATH"
fi
if [ "$VSCODE_AVAILABLE" = true ]; then
    ENV_SETUP="$ENV_SETUP\nVSCODE_PATH=$VSCODE_PATH"
fi

# Create cron entry with proper environment
CRON_ENTRY="$CRON_SCHEDULE PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
if [ "$CURSOR_AVAILABLE" = true ]; then
    CRON_ENTRY="$CRON_ENTRY CURSOR_PATH=$CURSOR_PATH"
fi
if [ "$VSCODE_AVAILABLE" = true ]; then
    CRON_ENTRY="$CRON_ENTRY VSCODE_PATH=$VSCODE_PATH"
fi
CRON_ENTRY="$CRON_ENTRY $NODE_PATH $SCRIPT_DIR/index.js >> $SCRIPT_DIR/logs/cron.log 2>&1"

# Check if cron entry already exists
if crontab -l 2>/dev/null | grep -q "$SCRIPT_DIR/index.js"; then
    echo "⚠️  Cron job already exists. Removing old entry..."
    crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/index.js" | crontab -
fi

# Add new cron entry
echo "📅 Adding cron job..."
(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -

echo "✅ Cron job installed successfully!"
echo ""
echo "Schedule: Every 6 hours"
echo "Logs: $SCRIPT_DIR/logs/cron.log"
if [ "$CURSOR_AVAILABLE" = true ]; then
    echo "Cursor path: $CURSOR_PATH"
fi
if [ "$VSCODE_AVAILABLE" = true ]; then
    echo "VS Code path: $VSCODE_PATH"
fi
echo ""
echo "To view current cron jobs: crontab -l"
echo "To remove this cron job: crontab -l | grep -v '$SCRIPT_DIR/index.js' | crontab -"
echo ""
echo "🔧 To test the script manually:"
echo "   cd $SCRIPT_DIR && npm test"
echo ""
echo "📊 To view logs:"
echo "   tail -f $SCRIPT_DIR/logs/cron.log" 