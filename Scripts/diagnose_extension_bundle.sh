#!/bin/bash

echo "=== System Extension Bundle Diagnostics ==="
echo

APP_PATH="/Applications/GigEVirtualCamera.app"
EXT_NAME="GigECameraExtension"
EXT_PATH="$APP_PATH/Contents/Library/SystemExtensions/$EXT_NAME.systemextension"

echo "1. Checking extension bundle structure..."
if [ -d "$EXT_PATH" ]; then
    echo "✓ Extension bundle exists at: $EXT_PATH"
    echo "  Contents:"
    find "$EXT_PATH" -type f -o -type d | sort
else
    echo "✗ Extension bundle not found at: $EXT_PATH"
    exit 1
fi

echo
echo "2. Checking Info.plist..."
if [ -f "$EXT_PATH/Contents/Info.plist" ]; then
    echo "✓ Info.plist exists"
    echo "  Bundle Identifier:"
    plutil -p "$EXT_PATH/Contents/Info.plist" | grep CFBundleIdentifier
    echo "  Executable name:"
    plutil -p "$EXT_PATH/Contents/Info.plist" | grep CFBundleExecutable
else
    echo "✗ Info.plist not found"
fi

echo
echo "3. Checking executable..."
EXEC_NAME=$(plutil -p "$EXT_PATH/Contents/Info.plist" 2>/dev/null | grep CFBundleExecutable | cut -d'"' -f4)
if [ -z "$EXEC_NAME" ]; then
    EXEC_NAME="$EXT_NAME"
fi

if [ -f "$EXT_PATH/Contents/MacOS/$EXEC_NAME" ]; then
    echo "✓ Executable exists: $EXEC_NAME"
    echo "  File info:"
    file "$EXT_PATH/Contents/MacOS/$EXEC_NAME"
else
    echo "✗ Executable not found: $EXT_PATH/Contents/MacOS/$EXEC_NAME"
fi

echo
echo "4. Checking code signature..."
codesign -dvvv "$EXT_PATH" 2>&1 | grep -E "Identifier|Format|Signature size|Authority|TeamIdentifier" | head -10

echo
echo "5. Checking if extension ID matches code..."
echo "Looking for extension ID in ExtensionManager.swift:"
grep -n "forExtensionWithIdentifier" /Users/lukechang/Github/hyperstudy-gige/GigECameraApp/ExtensionManager.swift | grep -v "//"

echo
echo "6. System extension cache status..."
echo "Run 'sudo killall -9 sysextd' to reset the system extension daemon"
echo "Run 'systemextensionsctl list' to see registered extensions"

echo
echo "7. Checking for duplicate extensions..."
find /Applications -name "*.systemextension" -path "*GigE*" 2>/dev/null

echo
echo "=== Recommendations ==="
echo "1. Ensure the extension bundle ID in code matches the actual bundle ID"
echo "2. Try: sudo killall -9 sysextd (requires password)"
echo "3. Restart the app and try installing again"
echo "4. Check Console.app for sysextd errors"