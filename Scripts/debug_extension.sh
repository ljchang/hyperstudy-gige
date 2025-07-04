#!/bin/bash

echo "=== Debugging CMIO Extension ==="
echo ""

# Check if extension is running
echo "1. Checking if extension process is running:"
ps aux | grep -i "gigecamera" | grep -v grep

echo ""
echo "2. Checking recent extension logs:"
log show --style syslog --predicate 'process == "com.lukechang.GigEVirtualCamera.Extension"' --last 5m 2>/dev/null | tail -20

echo ""
echo "3. Checking for CMIO errors:"
log show --style syslog --predicate 'subsystem CONTAINS "com.apple.cmio"' --last 2m 2>/dev/null | grep -i "gige" | tail -10

echo ""
echo "4. Checking App Group shared data:"
PLIST_PATH="$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist"
if [ -f "$PLIST_PATH" ]; then
    echo "App Group plist exists. Contents:"
    plutil -p "$PLIST_PATH" 2>/dev/null || echo "Could not read plist"
else
    echo "App Group plist not found"
fi

echo ""
echo "5. Starting live log stream for extension..."
echo "Open Photo Booth and select 'GigE Virtual Camera' to see activity"
echo "Press Ctrl+C to stop"
echo ""

# Stream logs
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"'