#!/bin/bash

# diagnose_distribution.sh - Diagnose distribution issues on target Mac
# Run this on the Mac where the app won't open

echo "GigE Virtual Camera Distribution Diagnostics"
echo "==========================================="
echo ""

# Check macOS version
echo "1. macOS Version:"
sw_vers
echo ""

# Check if app exists
APP_PATH="/Applications/GigEVirtualCamera.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: App not found at $APP_PATH"
    exit 1
fi

# Check code signature
echo "2. Code Signature Status:"
codesign --verify --deep --strict --verbose=2 "$APP_PATH" 2>&1
echo ""

# Check Gatekeeper status
echo "3. Gatekeeper Assessment:"
spctl -a -vvv "$APP_PATH" 2>&1
echo ""

# Check notarization
echo "4. Notarization Status:"
xcrun stapler validate "$APP_PATH" 2>&1
echo ""

# Check quarantine attributes
echo "5. Quarantine Attributes:"
xattr -l "$APP_PATH" 2>/dev/null | grep -A1 quarantine || echo "No quarantine attributes"
echo ""

# Check architecture
echo "6. Binary Architecture:"
lipo -info "$APP_PATH/Contents/MacOS/GigEVirtualCamera" 2>&1
echo ""

# Check minimum OS version
echo "7. Minimum OS Version Required:"
defaults read "$APP_PATH/Contents/Info.plist" LSMinimumSystemVersion 2>&1
echo ""

# Try to get more specific error
echo "8. Attempting to launch from command line:"
"$APP_PATH/Contents/MacOS/GigEVirtualCamera" 2>&1 | head -20
echo ""

# Check system logs
echo "9. Recent system logs (last 2 minutes):"
log show --predicate 'process == "launchd" OR process == "kernel" OR process == "amfid"' --last 2m 2>&1 | grep -i gige | head -20 || echo "No relevant logs found"
echo ""

echo "Diagnostics complete. Please share this output for troubleshooting."