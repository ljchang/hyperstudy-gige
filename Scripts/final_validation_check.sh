#!/bin/bash

echo "=== Final Validation Check ==="
echo

# 1. Check if running from correct location
echo "1. App location check:"
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "✓ App is in /Applications"
else
    echo "✗ App not in /Applications"
    exit 1
fi

# 2. Check extension structure
echo
echo "2. Extension structure:"
EXTENSION_PATH="/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
if [ -d "$EXTENSION_PATH" ]; then
    echo "✓ Extension found at: $EXTENSION_PATH"
    echo "  Contents:"
    find "$EXTENSION_PATH" -type f | head -10
else
    echo "✗ Extension not found"
fi

# 3. Verify bundle ID matches
echo
echo "3. Bundle ID verification:"
PLIST_BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "$EXTENSION_PATH/Contents/Info.plist" 2>/dev/null)
echo "  Info.plist Bundle ID: $PLIST_BUNDLE_ID"
echo "  Expected Bundle ID: com.lukechang.GigEVirtualCamera.Extension"
if [ "$PLIST_BUNDLE_ID" = "com.lukechang.GigEVirtualCamera.Extension" ]; then
    echo "✓ Bundle IDs match"
else
    echo "✗ Bundle ID mismatch!"
fi

# 4. Check code signing
echo
echo "4. Code signing verification:"
echo "App:"
codesign -vvv /Applications/GigEVirtualCamera.app 2>&1 | grep -E "satisfies|valid on disk|Error"
echo
echo "Extension:"
codesign -vvv "$EXTENSION_PATH" 2>&1 | grep -E "satisfies|valid on disk|Error"

# 5. Entitlements comparison
echo
echo "5. App Groups comparison:"
echo "App:"
codesign -d --entitlements :- /Applications/GigEVirtualCamera.app 2>/dev/null | grep -A2 "application-groups" | grep "<string>" | sed 's/.*<string>/  - /' | sed 's/<\/string>//'
echo
echo "Extension:"
codesign -d --entitlements :- "$EXTENSION_PATH" 2>/dev/null | grep -A2 "application-groups" | grep "<string>" | sed 's/.*<string>/  - /' | sed 's/<\/string>//'

# 6. Check provisioning profile
echo
echo "6. Provisioning profile app groups:"
security cms -D -i /Applications/GigEVirtualCamera.app/Contents/embedded.provisionprofile 2>/dev/null | plutil -p - | grep -A3 "com.apple.security.application-groups" | grep -v "com.apple.security.application-groups" | grep "=>" | sed 's/.*=> "/  - /' | sed 's/"//'

# 7. Check for common issues
echo
echo "7. Common validation issues:"

# Check if extension has provisioning profile (it shouldn't)
if [ -f "$EXTENSION_PATH/Contents/embedded.provisionprofile" ]; then
    echo "✗ Extension has provisioning profile (should be removed)"
else
    echo "✓ No provisioning profile in extension"
fi

# Check executable name
EXEC_NAME=$(plutil -extract CFBundleExecutable raw "$EXTENSION_PATH/Contents/Info.plist" 2>/dev/null)
if [ -f "$EXTENSION_PATH/Contents/MacOS/$EXEC_NAME" ]; then
    echo "✓ Executable found: $EXEC_NAME"
else
    echo "✗ Executable not found: $EXEC_NAME"
fi

# Check CMIO configuration
if plutil -extract CMIOExtension raw "$EXTENSION_PATH/Contents/Info.plist" &>/dev/null; then
    echo "✓ CMIOExtension key present"
    MACH_SERVICE=$(plutil -extract CMIOExtension.CMIOExtensionMachServiceName raw "$EXTENSION_PATH/Contents/Info.plist" 2>/dev/null)
    echo "  Mach service name: $MACH_SERVICE"
else
    echo "✗ CMIOExtension key missing"
fi

echo
echo "8. Summary:"
echo "If all checks pass but validation still fails, try:"
echo "  1. sudo systemextensionsctl reset"
echo "  2. Restart your Mac"
echo "  3. Check Console.app for detailed sysextd errors"