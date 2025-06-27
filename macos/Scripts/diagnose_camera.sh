#!/bin/bash

# Diagnose why the GigE Virtual Camera isn't showing up in macOS

echo "=== GigE Virtual Camera Diagnostics ==="
echo "Date: $(date)"
echo

# 1. Check if extension is registered
echo "1. Checking for registered camera extensions:"
pluginkit -mA -i com.apple.cmio | grep -i "camera\|gige" || echo "  ❌ No camera extensions found"
echo

# 2. Check for our specific extension
echo "2. Looking for GigE extension:"
pluginkit -m -i com.lukechang.GigEVirtualCamera.Extension 2>&1 || echo "  ❌ Extension not found"
echo

# 3. Check system extension status
echo "3. System extensions status:"
systemextensionsctl list 2>&1 | grep -i "gige\|lukechang" || echo "  ℹ️  No system extensions (this is OK for app extensions)"
echo

# 4. Check if app is running
echo "4. Checking if app is running:"
ps aux | grep -i "GigEVirtualCamera" | grep -v grep || echo "  ❌ App not running"
echo

# 5. Check camera permissions
echo "5. Camera permissions in System Settings:"
echo "  ℹ️  Please check: System Settings > Privacy & Security > Camera"
echo "  The app should appear here after first launch"
echo

# 6. Check recent system logs
echo "6. Recent CMIO logs:"
log show --predicate 'subsystem == "com.apple.cmio" OR subsystem == "com.apple.CoreMediaIO"' --last 5m --info 2>/dev/null | grep -i "error\|fail\|deny" | tail -10 || echo "  ✅ No recent errors"
echo

# 7. Check if running from Xcode
echo "7. Build location check:"
if [[ "$PWD" == *"DerivedData"* ]]; then
    echo "  ⚠️  Running from Xcode build - extensions may not register properly"
    echo "  Try: Copy app to /Applications and run from there"
else
    echo "  ✅ Not running from DerivedData"
fi
echo

# 8. Security assessment
echo "8. Gatekeeper assessment:"
APP_PATH=$(find /Applications -name "GigEVirtualCamera.app" 2>/dev/null | head -1)
if [ -n "$APP_PATH" ]; then
    spctl --assess --verbose "$APP_PATH" 2>&1 || echo "  ⚠️  App not notarized"
else
    echo "  ℹ️  App not found in /Applications"
fi
echo

# 9. Check SIP status
echo "9. System Integrity Protection (SIP):"
csrutil status | grep -q "enabled" && echo "  ✅ SIP is enabled (normal)" || echo "  ⚠️  SIP is disabled"
echo

# 10. Test in apps
echo "10. Testing in applications:"
echo "  Try opening these apps to see if camera appears:"
echo "  - Photo Booth"
echo "  - FaceTime" 
echo "  - Zoom"
echo "  - QuickTime Player (File > New Movie Recording)"
echo

# 11. Manual registration attempt
echo "11. Attempting manual registration:"
echo "  To manually register the extension:"
echo "  1. Copy app to /Applications/"
echo "  2. Launch the app"
echo "  3. Grant camera permissions when prompted"
echo "  4. Restart the app"
echo

# 12. Reset Camera Extensions
echo "12. To reset all camera extensions (if needed):"
echo "  sudo killall -9 cmioextension"
echo "  rm -rf ~/Library/Caches/com.apple.cmio*"
echo "  Then restart your Mac"