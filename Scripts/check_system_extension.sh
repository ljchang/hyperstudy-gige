#!/bin/bash

# Check system extension status for GigE Virtual Camera

echo "=== Checking System Extension Status ==="
echo

# Check if running from /Applications
APP_PATH="/Applications/GigEVirtualCamera.app"
if [ -d "$APP_PATH" ]; then
    echo "✅ App found in /Applications"
else
    echo "❌ App not found in /Applications"
    echo "   System extensions can only be activated from /Applications"
fi

echo
echo "=== System Extensions List ==="
systemextensionsctl list

echo
echo "=== Checking for our extension ==="
if systemextensionsctl list | grep -q "com.lukechang.GigEVirtualCamera.Extension"; then
    echo "✅ Extension found in system"
    
    # Get the status
    STATUS=$(systemextensionsctl list | grep "com.lukechang.GigEVirtualCamera.Extension" | awk -F'[\\[\\]]' '{print $2}')
    echo "   Status: [$STATUS]"
    
    if [[ "$STATUS" == *"activated enabled"* ]]; then
        echo "   ✅ Extension is activated and enabled"
    elif [[ "$STATUS" == *"terminated waiting to uninstall"* ]]; then
        echo "   ⚠️  Extension is waiting to be uninstalled (reboot required)"
    else
        echo "   ⚠️  Extension is not fully activated"
    fi
else
    echo "❌ Extension not found in system"
fi

echo
echo "=== Checking CMIO devices ==="
system_profiler SPCameraDataType | grep -A5 "GigE Virtual Camera" || echo "❌ Virtual camera not found in system"

echo
echo "=== Checking logs for errors ==="
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' --last 5m | grep -i error | tail -5

echo
echo "=== Troubleshooting Tips ==="
echo "1. If extension not found: Make sure app is in /Applications and has been run at least once"
echo "2. If extension needs approval: Go to System Settings > Privacy & Security"
echo "3. If waiting to uninstall: Restart your Mac"
echo "4. If virtual camera not appearing: Check Console.app for detailed logs"