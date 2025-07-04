#!/bin/bash

echo "=== GigE Virtual Camera Extension Diagnostic ==="
echo ""

# Check if app is running
echo "1. Checking if app is running..."
if pgrep -f "GigEVirtualCamera.app" > /dev/null; then
    echo "✅ App is running"
else
    echo "❌ App is not running"
fi
echo ""

# Check extension status
echo "2. Checking system extension status..."
systemextensionsctl list | grep -A5 "com.lukechang" || echo "❌ No extension found"
echo ""

# Check if extension bundle exists in app
echo "3. Checking extension bundle in app..."
if [ -d "/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension" ]; then
    echo "✅ Extension bundle exists in app"
    echo "   Info.plist contents:"
    plutil -p "/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist" | grep -E "(CFBundleIdentifier|CMIOExtensionMachServiceName)" || echo "   ❌ Could not read Info.plist"
else
    echo "❌ Extension bundle not found in app"
fi
echo ""

# Check if virtual camera is visible to system
echo "4. Checking if virtual camera is visible to system..."
system_profiler SPCameraDataType | grep -A5 "GigE" || echo "❌ Virtual camera not visible"
echo ""

# Check for extension process
echo "5. Checking for extension process..."
ps aux | grep -i "GigEVirtualCameraExtension" | grep -v grep || echo "❌ Extension process not running"
echo ""

# Check Photo Booth
echo "6. Checking Photo Booth status..."
if pgrep -f "Photo Booth" > /dev/null; then
    echo "✅ Photo Booth is running"
    echo "   Please select 'GigE Virtual Camera' in Photo Booth now..."
else
    echo "❌ Photo Booth is not running"
fi
echo ""

# Monitor for extension startup
echo "7. Monitoring for extension startup (10 seconds)..."
echo "   Select 'GigE Virtual Camera' in Photo Booth NOW!"

timeout 10 bash -c '
while true; do
    if pgrep -f "GigEVirtualCameraExtension" > /dev/null; then
        echo "   ✅ Extension process started!"
        ps aux | grep -i "GigEVirtualCameraExtension" | grep -v grep
        exit 0
    fi
    sleep 0.5
done
' || echo "   ❌ Extension did not start within 10 seconds"

echo ""

# Check logs for errors
echo "8. Checking recent logs for errors..."
log show --predicate 'process == "GigEVirtualCamera" OR process == "GigEVirtualCameraExtension" OR subsystem == "com.lukechang.GigEVirtualCamera"' --last 1m --info 2>&1 | grep -E "(error|fail|denied|reject)" | tail -10 || echo "   No recent errors found"

echo ""
echo "=== Diagnostic Complete ==="