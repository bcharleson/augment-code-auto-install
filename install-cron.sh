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

# Create cron entry
CRON_ENTRY="$CRON_SCHEDULE $NODE_PATH $SCRIPT_DIR/index.js >> $SCRIPT_DIR/logs/cron.log 2>&1"

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
echo ""
echo "To view current cron jobs: crontab -l"
echo "To remove this cron job: crontab -l | grep -v '$SCRIPT_DIR/index.js' | crontab -"
echo ""
echo "🔧 To test the script manually:"
echo "   cd $SCRIPT_DIR && npm test"
echo ""
echo "📊 To view logs:"
echo "   tail -f $SCRIPT_DIR/logs/cron.log" 