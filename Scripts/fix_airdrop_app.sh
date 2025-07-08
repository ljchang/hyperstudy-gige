#!/bin/bash

# fix_airdrop_app.sh - Fix app transferred via AirDrop that won't open
# Run this on the target Mac after copying the app

echo "GigE Virtual Camera AirDrop Fix"
echo "==============================="
echo ""

APP_PATH="/Applications/GigEVirtualCamera.app"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: App not found at $APP_PATH"
    echo "Please drag the app to Applications folder first"
    exit 1
fi

echo "1. Removing quarantine attributes..."
xattr -cr "$APP_PATH"
echo "✓ Quarantine attributes removed"
echo ""

echo "2. Checking code signature..."
if codesign --verify --deep --strict "$APP_PATH" 2>&1; then
    echo "✓ Code signature is valid"
else
    echo "✗ Code signature verification failed"
    codesign -dvvv "$APP_PATH" 2>&1 | head -20
fi
echo ""

echo "3. Checking Gatekeeper status..."
spctl -a -vvv "$APP_PATH" 2>&1
echo ""

echo "4. Trying to launch the app..."
open "$APP_PATH"
echo ""

echo "If the app still doesn't open, try:"
echo "1. Right-click the app and choose 'Open'"
echo "2. Go to System Settings > Privacy & Security"
echo "3. Look for a message about GigEVirtualCamera and click 'Open Anyway'"
echo ""
echo "For more diagnostics, run:"
echo "  /Applications/GigEVirtualCamera.app/Contents/MacOS/GigEVirtualCamera"
echo "This will show any specific error messages."