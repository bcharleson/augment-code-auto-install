#!/bin/bash

# Augment Monitor Setup Test Script
# This script tests if everything is configured correctly

set -e

echo "🔍 Testing Augment Monitor Setup..."
echo "=================================="

# Test 1: Check Node.js
echo "1. Testing Node.js..."
NODE_PATH=$(which node)
if [ -n "$NODE_PATH" ]; then
    echo "   ✅ Node.js found: $NODE_PATH"
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js version: $NODE_VERSION"
else
    echo "   ❌ Node.js not found. Please install Node.js."
    exit 1
fi

# Test 2: Check Cursor CLI
echo ""
echo "2. Testing Cursor CLI..."
CURSOR_PATH=$(which cursor 2>/dev/null || echo "")
if [ -n "$CURSOR_PATH" ]; then
    echo "   ✅ Cursor CLI found: $CURSOR_PATH"
    CURSOR_VERSION=$(cursor --version 2>/dev/null || echo "Version check failed")
    echo "   ✅ Cursor version: $CURSOR_VERSION"
else
    echo "   ❌ Cursor CLI not found in PATH"
    echo "   💡 Try these locations:"
    echo "      - /opt/homebrew/bin/cursor (Homebrew)"
    echo "      - /usr/local/bin/cursor (Manual install)"
    echo "      - /Applications/Cursor.app/Contents/Resources/app/bin/cursor (App bundle)"
    echo "   💡 Or install Cursor CLI: cursor --install-extension"
    exit 1
fi

# Test 3: Check if Augment extension is installed
echo ""
echo "3. Testing Augment Extension..."
AUGMENT_VERSION=$(cursor --list-extensions --show-versions | grep -i augment || echo "")
if [ -n "$AUGMENT_VERSION" ]; then
    echo "   ✅ Augment extension found: $AUGMENT_VERSION"
else
    echo "   ❌ Augment extension not found"
    echo "   💡 Install it: cursor --install-extension augment"
    exit 1
fi

# Test 4: Check npm dependencies
echo ""
echo "4. Testing npm dependencies..."
if [ -f "package.json" ]; then
    echo "   ✅ package.json found"
    if [ -d "node_modules" ]; then
        echo "   ✅ node_modules found"
    else
        echo "   ⚠️  node_modules not found. Run: npm install"
        exit 1
    fi
else
    echo "   ❌ package.json not found. Are you in the correct directory?"
    exit 1
fi

# Test 5: Test the main script
echo ""
echo "5. Testing main script..."
if [ -f "index.js" ]; then
    echo "   ✅ index.js found"
    echo "   🧪 Running dry-run test..."
    npm test
    echo "   ✅ Script test completed successfully!"
else
    echo "   ❌ index.js not found"
    exit 1
fi

# Test 6: Check cron job (if installed)
echo ""
echo "6. Checking cron job status..."
if crontab -l 2>/dev/null | grep -q "index.js"; then
    echo "   ✅ Cron job is installed"
    echo "   📅 Current cron jobs:"
    crontab -l | grep "index.js" | sed 's/^/      /'
else
    echo "   ⚠️  No cron job found"
    echo "   💡 Install with: npm run install-cron"
fi

echo ""
echo "🎉 Setup test completed!"
echo "=================================="
echo "✅ All tests passed - your setup is ready!"
echo ""
echo "Next steps:"
echo "  - Run 'npm start' to check for updates"
echo "  - Run 'npm run install-cron' to set up automatic updates"
echo "  - Check logs with 'tail -f logs/cron.log'" 