#!/bin/bash

echo "=== Debug Extension Not Creating Device ==="
echo

# 1. Force camera enumeration to trigger extension
echo "1. Triggering extension by opening QuickTime..."
open -a "QuickTime Player"
sleep 3

# 2. Check if extension started
echo
echo "2. Extension process:"
ps aux | grep -i "GigECameraExtension" | grep -v grep || echo "Not running"

# 3. Check CMIO devices
echo
echo "3. CMIO devices:"
swift /Users/lukechang/Github/hyperstudy-gige/Scripts/list_cmio_devices.swift 2>&1 | grep -E "Name:|GigE|Error" || echo "No devices found"

# 4. Check system logs
echo
echo "4. Recent extension logs:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 2m | tail -20

echo
echo "5. CMIO manager logs:"
log show --predicate 'process == "cmioextensionmanagerd"' --last 2m | grep -i "gige\|lukechang" | tail -20

echo
echo "6. Check if extension is properly signed:"
codesign -dvvv /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep -E "Signature|Authority|TeamIdentifier"

echo
echo "7. Possible issues:"
echo "   - Extension not starting due to code signing"
echo "   - Extension crashing on startup"
echo "   - Mach service name mismatch"
echo "   - Missing entitlements"