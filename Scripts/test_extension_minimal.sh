#!/bin/bash

echo "=== Testing Minimal Extension Functionality ==="
echo ""

# 1. Check if extension is installed
echo "1. System extension status:"
systemextensionsctl list | grep -A2 "com.lukechang" || echo "Not found"

# 2. Force uninstall and reinstall
echo ""
echo "2. Resetting extension..."
systemextensionsctl uninstall S368GH6KF7 com.lukechang.GigEVirtualCamera.Extension || true
sleep 2

# 3. Click Install Extension in the app
echo ""
echo "3. Please click 'Install Extension' in the GigEVirtualCamera app"
echo "   Waiting for installation..."
sleep 10

# 4. Check status again
echo ""
echo "4. New status:"
systemextensionsctl list | grep -A2 "com.lukechang" || echo "Not found"

# 5. Check for any sandbox violations
echo ""
echo "5. Checking for sandbox violations..."
log show --predicate 'eventMessage CONTAINS "Sandbox" AND eventMessage CONTAINS "GigE"' --last 1m --info 2>&1 | tail -10

# 6. Check if extension binary is executable
echo ""
echo "6. Checking extension binary:"
EXTENSION_PATH="/Library/SystemExtensions/*/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/MacOS/GigECameraExtension"
ls -la $EXTENSION_PATH 2>/dev/null || echo "Extension binary not found in /Library/SystemExtensions"

echo ""
echo "=== Summary ==="
echo "If the extension is installed but not running when clients connect,"
echo "there may be a code signing or entitlement issue preventing launch."