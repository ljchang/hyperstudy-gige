#!/bin/bash

echo "=== Debugging System Extension Issue ==="
echo

# 1. Check SIP status
echo "1. SIP Status:"
csrutil status
echo

# 2. Check if extension bundle is valid
echo "2. Extension Bundle Structure:"
ls -la /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/
echo

# 3. Check binary architecture
echo "3. Extension Binary Info:"
file /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/MacOS/GigECameraExtension
echo

# 4. Check Info.plist
echo "4. Extension Info.plist (key values):"
plutil -p /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist | grep -E "CFBundleIdentifier|CFBundlePackageType|CMIOExtension"
echo

# 5. Check code signature
echo "5. Code Signature Status:"
codesign -dvvv /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep -E "Format|CDHash|Signature"
echo

# 6. List current extensions
echo "6. Current System Extensions:"
systemextensionsctl list
echo

# 7. Check if extension process is running
echo "7. Extension Process Check:"
ps aux | grep -i GigECameraExtension | grep -v grep || echo "Extension process not running"
echo

# 8. Try to find any system logs about our extension
echo "8. Recent System Logs (filtered):"
log show --last 5m --predicate 'eventMessage CONTAINS "com.lukechang.GigEVirtualCamera"' 2>/dev/null | tail -20 || echo "No recent logs found"

echo
echo "=== Potential Issues ==="
echo "- If SIP is enabled, extensions require proper signing"
echo "- Extension must be inside app bundle at correct path"
echo "- Info.plist must have correct bundle type (SYSX)"
echo "- Binary must match system architecture"
echo "- App must be in /Applications"