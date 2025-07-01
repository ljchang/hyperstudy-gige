#!/bin/bash

echo "=== Debugging Validation Failure ==="
echo

# Check if running from /Applications
echo "1. Checking app location..."
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "✓ App is in /Applications"
else
    echo "✗ App not found in /Applications"
    exit 1
fi

# Check bundle structure
echo
echo "2. Checking bundle structure..."
EXTENSION_PATH="/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
if [ -d "$EXTENSION_PATH" ]; then
    echo "✓ Extension found at correct path"
    echo "  Contents:"
    find "$EXTENSION_PATH" -type f -name "*.plist" -o -name "GigECameraExtension" | sed 's|^|  |'
else
    echo "✗ Extension not found at expected path"
    echo "  Looking for extensions:"
    find /Applications/GigEVirtualCamera.app -name "*.systemextension" -type d
fi

# Check Info.plist
echo
echo "3. Extension Info.plist contents:"
if [ -f "$EXTENSION_PATH/Contents/Info.plist" ]; then
    plutil -p "$EXTENSION_PATH/Contents/Info.plist" | grep -E "CFBundle|CMIOExtension|LSMinimum"
else
    echo "✗ Info.plist not found"
fi

# Check code signing
echo
echo "4. Code signing status:"
echo "App:"
codesign -dvvv /Applications/GigEVirtualCamera.app 2>&1 | grep -E "Authority|TeamIdentifier|Bundle ID"
echo
echo "Extension:"
codesign -dvvv "$EXTENSION_PATH" 2>&1 | grep -E "Authority|TeamIdentifier|Bundle ID"

# Check entitlements match
echo
echo "5. Checking if TeamIdentifier matches..."
APP_TEAM=$(codesign -dvvv /Applications/GigEVirtualCamera.app 2>&1 | grep TeamIdentifier | cut -d'=' -f2)
EXT_TEAM=$(codesign -dvvv "$EXTENSION_PATH" 2>&1 | grep TeamIdentifier | cut -d'=' -f2)
if [ "$APP_TEAM" = "$EXT_TEAM" ]; then
    echo "✓ Team IDs match: $APP_TEAM"
else
    echo "✗ Team ID mismatch! App: $APP_TEAM, Extension: $EXT_TEAM"
fi

# Check for common issues
echo
echo "6. Common validation issues:"

# Check if extension is a universal binary
echo -n "  Extension architecture: "
lipo -info "$EXTENSION_PATH/Contents/MacOS/GigECameraExtension" 2>&1 | sed 's/.*: //'

# Check if all required frameworks are present
echo -n "  Required frameworks: "
if otool -L "$EXTENSION_PATH/Contents/MacOS/GigECameraExtension" | grep -q "SystemExtensions"; then
    echo "✗ Extension should not link against SystemExtensions.framework"
else
    echo "✓ Not linking against SystemExtensions.framework"
fi

# Recent console messages
echo
echo "7. Recent console messages (run 'log stream' in another terminal for live updates):"
echo "   Filter with: log stream --predicate 'subsystem == \"com.apple.sysextd\"'"