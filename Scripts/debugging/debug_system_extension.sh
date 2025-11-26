#!/bin/bash

echo "=== System Extension Debug Script ==="
echo

echo "1. Checking if running from /Applications..."
if [[ "$PWD" == "/Applications"* ]]; then
    echo "✓ Running from /Applications"
else
    echo "✗ Not running from /Applications - System extensions require this!"
fi
echo

echo "2. Checking system extension developer mode..."
systemextensionsctl developer
echo

echo "3. Checking installed system extensions..."
systemextensionsctl list
echo

echo "4. Checking app signature..."
codesign -dv --verbose=4 /Applications/GigEVirtualCamera.app 2>&1 | grep -E "(Authority|TeamIdentifier|Signature|entitled)"
echo

echo "5. Checking extension signature..."
codesign -dv --verbose=4 /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep -E "(Authority|TeamIdentifier|Signature|entitled)"
echo

echo "6. Checking if extension is properly embedded..."
if [ -f "/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/MacOS/GigECameraExtension" ]; then
    echo "✓ Extension binary found"
else
    echo "✗ Extension binary not found!"
fi
echo

echo "7. Checking system logs for extension errors..."
echo "Recent system extension logs:"
log show --predicate 'subsystem == "com.apple.extensionKit" OR subsystem == "com.apple.cmio"' --style syslog --last 5m | grep -i "gige\|camera" | tail -20
echo

echo "8. Checking if app has hardened runtime..."
codesign -d --entitlements - /Applications/GigEVirtualCamera.app 2>&1 | grep -A1 "runtime"
echo

echo "9. Checking provisioning profile entitlements..."
echo "App profile:"
security cms -D -i /Applications/GigEVirtualCamera.app/Contents/embedded.provisionprofile 2>/dev/null | grep -E "(com.apple.developer.system-extension|Name)" | head -5
echo
echo "Extension profile:"
security cms -D -i /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/embedded.provisionprofile 2>/dev/null | grep -E "(com.apple.developer|Name)" | head -10
echo

echo "=== Recommendations ==="
echo "If system extension is not prompting:"
echo "1. Ensure developer mode is ON: sudo systemextensionsctl developer on"
echo "2. Update extension provisioning profile on developer.apple.com"
echo "3. Clean build and reinstall the app"
echo "4. Check Console.app for detailed error messages"