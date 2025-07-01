#!/bin/bash

# Manual System Extension Installation Helper
# Use this when the automatic installation through the app doesn't work

echo "=== Manual System Extension Installation ==="
echo
echo "This script will help manually install the GigE Camera system extension."
echo

# Check if running with SIP disabled
csrutil status | grep -q "disabled"
if [ $? -ne 0 ]; then
    echo "⚠️  WARNING: SIP appears to be enabled. This may not work."
    echo "   To disable SIP temporarily:"
    echo "   1. Restart and hold power button"
    echo "   2. Select Options, then Terminal"
    echo "   3. Run: csrutil disable"
    echo "   4. Restart"
    echo
fi

# Path to extension
EXTENSION_PATH="/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension"

if [ ! -d "$EXTENSION_PATH" ]; then
    echo "❌ Extension not found at: $EXTENSION_PATH"
    echo "   Please build and install the app first."
    exit 1
fi

echo "Found extension at: $EXTENSION_PATH"
echo

# Try to load extension using systemextensionsctl (may not work on newer macOS)
echo "Attempting to load extension..."
systemextensionsctl install "$EXTENSION_PATH" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Extension installation initiated"
else
    echo "⚠️  Direct installation failed (expected on newer macOS)"
    echo
    echo "Alternative method:"
    echo "1. Open the GigE Virtual Camera app"
    echo "2. Click 'Install Extension' button"
    echo "3. If prompted, go to System Settings > Privacy & Security"
    echo "4. Look for a message about the blocked extension at the bottom"
    echo "5. Click 'Allow' next to the extension"
    echo "6. Enter your password when prompted"
    echo "7. The extension should then activate"
fi

echo
echo "Checking current status..."
systemextensionsctl list

echo
echo "To verify the extension is working:"
echo "1. Check if it appears in: systemextensionsctl list"
echo "2. Open QuickTime Player"
echo "3. File > New Movie Recording"
echo "4. Click the dropdown next to record button"
echo "5. Look for 'GigE Virtual Camera'"