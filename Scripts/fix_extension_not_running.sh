#!/bin/bash

echo "=== Fixing Extension Not Running ==="
echo

# 1. Kill the app first
echo "1. Stopping GigE app..."
killall GigEVirtualCamera 2>/dev/null

# 2. Check current extension status
echo
echo "2. Current extension status:"
systemextensionsctl list | grep -A1 "GigE"

# 3. List CMIO devices
echo
echo "3. Current CMIO devices:"
swift /Users/lukechang/Github/hyperstudy-gige/Scripts/list_cmio_devices.swift 2>/dev/null | grep -E "Name:|GigE" || echo "Error listing devices"

# 4. Force extension restart
echo
echo "4. To force extension restart, run in Terminal:"
echo "   sudo killall -9 cmioextensionmanagerd"
echo

# 5. Start a camera app to trigger extension loading
echo "5. Opening QuickTime to trigger extension..."
open -a "QuickTime Player"

sleep 2

# 6. Check if extension started
echo
echo "6. Checking if extension process started..."
ps aux | grep -i "GigECameraExtension" | grep -v grep || echo "Extension not running yet"

echo
echo "7. Start GigE app again..."
open /Applications/GigEVirtualCamera.app

echo
echo "8. If extension still not working:"
echo "   - Go to System Settings > General > Login Items & Extensions > Camera Extensions"
echo "   - Toggle the GigE Camera Extension off and on"
echo "   - Or restart your Mac"