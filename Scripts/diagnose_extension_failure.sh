#!/bin/bash

echo "=== System Extension Diagnostic ==="
echo

# 1. Check developer mode
echo "1. Developer Mode Status:"
systemextensionsctl developer
echo

# 2. Check SIP
echo "2. SIP Status:"
csrutil status
echo

# 3. Check app location
echo "3. App Location Check:"
if [[ "/Applications/GigEVirtualCamera.app" == /Applications/* ]]; then
    echo "✅ App is in /Applications"
else
    echo "❌ App must be in /Applications"
fi
echo

# 4. Check bundle structure
echo "4. Extension Bundle Check:"
EXTENSION="/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension"
if [ -d "$EXTENSION" ]; then
    echo "✅ Extension bundle exists"
    echo "   Contents:"
    ls -la "$EXTENSION/Contents/"
else
    echo "❌ Extension bundle not found"
fi
echo

# 5. Check binary
echo "5. Extension Binary Check:"
if [ -f "$EXTENSION/Contents/MacOS/GigECameraExtension" ]; then
    echo "✅ Binary exists"
    file "$EXTENSION/Contents/MacOS/GigECameraExtension"
    ls -la "$EXTENSION/Contents/MacOS/GigECameraExtension"
else
    echo "❌ Binary not found"
fi
echo

# 6. Check Info.plist
echo "6. Key Info.plist Values:"
if [ -f "$EXTENSION/Contents/Info.plist" ]; then
    echo "Bundle ID: $(plutil -p "$EXTENSION/Contents/Info.plist" | grep CFBundleIdentifier | cut -d'"' -f4)"
    echo "Package Type: $(plutil -p "$EXTENSION/Contents/Info.plist" | grep CFBundlePackageType | cut -d'"' -f4)"
    echo "Mach Service: $(plutil -p "$EXTENSION/Contents/Info.plist" | grep CMIOExtensionMachServiceName | cut -d'"' -f4)"
fi
echo

# 7. Check code signature
echo "7. Code Signature Check:"
echo "App signature:"
codesign -dvvv /Applications/GigEVirtualCamera.app 2>&1 | grep -E "Signature|Authority|TeamIdentifier|Format" | head -5
echo
echo "Extension signature:"
codesign -dvvv "$EXTENSION" 2>&1 | grep -E "Signature|Authority|TeamIdentifier|Format" | head -5
echo

# 8. Try to run extension directly (will fail but shows errors)
echo "8. Direct Execution Test:"
echo "Attempting to run extension binary directly (expected to fail):"
"$EXTENSION/Contents/MacOS/GigECameraExtension" 2>&1 | head -10 || echo "Binary execution test complete"
echo

echo "=== Recommendations ==="
echo "If all checks pass but extension still won't load:"
echo "1. The issue might be with ad-hoc signing"
echo "2. Try building with a proper Developer ID certificate"
echo "3. Check Console.app for more detailed sysextd errors"
echo "4. The CMIOExtensionMachServiceName might need adjustment"