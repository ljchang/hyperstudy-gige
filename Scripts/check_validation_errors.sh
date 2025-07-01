#!/bin/bash

echo "=== Checking for Extension Validation Errors ==="
echo

# Check extension validation
echo "1. Verifying extension code signature..."
codesign -vvv --deep --strict /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1

echo
echo "2. Checking extension Info.plist..."
plutil -lint /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist

echo
echo "3. Checking for required Info.plist keys..."
plutil -p /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist | grep -E "LSMinimumSystemVersion|CFBundlePackageType|NSExtension|CMIOExtension"

echo
echo "4. Checking app signature..."
codesign -vvv --deep --strict /Applications/GigEVirtualCamera.app 2>&1 | grep -E "valid|satisfy|Error"

echo
echo "5. Checking entitlements match..."
echo "App entitlements:"
codesign -d --entitlements - /Applications/GigEVirtualCamera.app 2>&1 | grep -A1 "application-groups"

echo
echo "Extension entitlements:"
codesign -d --entitlements - /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep -A1 "application-groups"

echo
echo "6. Checking bundle IDs..."
echo "App Bundle ID:"
plutil -p /Applications/GigEVirtualCamera.app/Contents/Info.plist | grep CFBundleIdentifier
echo "Extension Bundle ID:"
plutil -p /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist | grep CFBundleIdentifier

echo
echo "7. Recent sysextd logs..."
log stream --predicate 'process == "sysextd"' --last 30s 2>&1 | grep -i "com.lukechang\|validation\|fail" || echo "No recent errors found"