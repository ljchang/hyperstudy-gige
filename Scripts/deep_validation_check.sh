#!/bin/bash

echo "=== Deep Validation Check ==="
echo

# Check provisioning profiles
echo "1. Checking provisioning profiles..."
echo "App provisioning:"
security cms -D -i /Applications/GigEVirtualCamera.app/Contents/embedded.provisionprofile 2>/dev/null | plutil -p - | grep -E "TeamIdentifier|application-identifier|com.apple.developer" | head -10 || echo "  No provisioning profile found (OK for Developer ID)"

echo
echo "2. Checking if app group is in provisioning profile..."
if [ -f "/Applications/GigEVirtualCamera.app/Contents/embedded.provisionprofile" ]; then
    security cms -D -i /Applications/GigEVirtualCamera.app/Contents/embedded.provisionprofile 2>/dev/null | plutil -p - | grep -A5 "com.apple.security.application-groups"
else
    echo "  No provisioning profile (using Developer ID signing)"
fi

# Check actual entitlements vs what's in the binary
echo
echo "3. Comparing entitlements..."
echo "App binary entitlements:"
codesign -d --entitlements :- /Applications/GigEVirtualCamera.app 2>/dev/null | plutil -p - | grep -A2 "application-groups\|system-extension"

echo
echo "Extension binary entitlements:"
codesign -d --entitlements :- /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>/dev/null | plutil -p - | grep -A2 "application-groups"

# Check file permissions
echo
echo "4. Checking file permissions..."
ls -la /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/
ls -la /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/

# Check if running with SIP
echo
echo "5. System Integrity Protection status:"
csrutil status

# Check for duplicate bundle IDs
echo
echo "6. Checking for duplicate extensions..."
find /Applications -name "*.systemextension" -type d 2>/dev/null | while read ext; do
    if plutil -p "$ext/Contents/Info.plist" 2>/dev/null | grep -q "com.lukechang.GigEVirtualCamera.Extension"; then
        echo "Found: $ext"
    fi
done

# Check signing certificate details
echo
echo "7. Certificate validation..."
CERT=$(codesign -dvvv /Applications/GigEVirtualCamera.app 2>&1 | grep "Authority=Apple Development" | head -1 | sed 's/Authority=//')
if [ -n "$CERT" ]; then
    echo "Certificate: $CERT"
    security find-identity -v -p codesigning | grep "$CERT"
fi

# Check if extension plist has all required keys
echo
echo "8. Extension Info.plist validation..."
PLIST="/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist"
for key in CFBundleIdentifier CFBundleExecutable CFBundlePackageType NSExtension CMIOExtension LSMinimumSystemVersion; do
    if plutil -p "$PLIST" | grep -q "\"$key\""; then
        echo "  ✓ $key present"
    else
        echo "  ✗ $key missing"
    fi
done

# Check Mach service name
echo
echo "9. Mach service configuration..."
plutil -p "$PLIST" | grep -A2 "CMIOExtensionMachServiceName"

echo
echo "10. Testing with systemextensionsctl..."
echo "Run this command to see detailed errors:"
echo "  systemextensionsctl developer on"
echo "  systemextensionsctl list"
echo
echo "To monitor live logs, run in another terminal:"
echo "  log stream --predicate 'subsystem == \"com.apple.sysextd\" OR process == \"sysextd\"' --style compact"