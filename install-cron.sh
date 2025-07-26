#!/bin/bash

# Augment Monitor Cron Job Installation Script
# This script sets up automatic monitoring for Augment extension updates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_PATH=$(which node)
CRON_SCHEDULE="0 */6 * * *"  # Every 6 hours

echo "🚀 Installing Augment Monitor Cron Job..."
echo "Script directory: $SCRIPT_DIR"
echo "Node.js path: $NODE_PATH"
echo "Schedule: $CRON_SCHEDULE"

# Check if node is available
if [ ! -f "$NODE_PATH" ]; then
    echo "❌ Error: Node.js not found. Please install Node.js first."
    exit 1
fi

# Check if the main script exists
if [ ! -f "$SCRIPT_DIR/index.js" ]; then
    echo "❌ Error: index.js not found in $SCRIPT_DIR"
    exit 1
fi

# Make the script executable
chmod +x "$SCRIPT_DIR/index.js"

# Detect cursor path and create robust PATH
CURSOR_PATH=$(which cursor 2>/dev/null || echo "")
if [ -z "$CURSOR_PATH" ]; then
    echo "⚠️  Warning: cursor command not found in PATH"
    echo "   Common locations: /opt/homebrew/bin/cursor, /usr/local/bin/cursor, /Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    echo "   Please ensure Cursor CLI is installed and accessible"
fi

# Create comprehensive PATH for cron environment
CRON_PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
if [ -n "$CURSOR_PATH" ]; then
    CURSOR_DIR=$(dirname "$CURSOR_PATH")
    if [[ ":$CRON_PATH:" != *":$CURSOR_DIR:"* ]]; then
        CRON_PATH="$CURSOR_DIR:$CRON_PATH"
    fi
fi

# Create cron entry with detected paths
CRON_ENTRY="$CRON_SCHEDULE PATH=$CRON_PATH $NODE_PATH $SCRIPT_DIR/index.js >> $SCRIPT_DIR/logs/cron.log 2>&1"

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"

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
echo "Detected cursor path: ${CURSOR_PATH:-"Not found"}"
echo "Cron PATH: $CRON_PATH"
echo ""
echo "To view current cron jobs: crontab -l"
echo "To remove this cron job: crontab -l | grep -v '$SCRIPT_DIR/index.js' | crontab -"
echo ""
echo "🔧 To test the script manually:"
echo "   cd $SCRIPT_DIR && npm test"
echo ""
echo "📊 To view logs:"
echo "   tail -f $SCRIPT_DIR/logs/cron.log"
echo ""
echo "🔍 To verify cron job is working:"
echo "   tail -f $SCRIPT_DIR/logs/cron.log"
echo "   (Wait for next scheduled run or test manually)" 