#!/bin/bash

echo "=== Debugging Frame Sending to Virtual Camera ==="
echo

# 1. Check if the virtual camera is visible to the system
echo "1. Virtual camera in system:"
system_profiler SPCameraDataType | grep -A5 "GigE" || echo "GigE Virtual Camera not found"

echo
echo "2. Check recent logs for frame sending:"
log show --predicate 'process == "GigEVirtualCamera" AND (message CONTAINS "frame" OR message CONTAINS "Frame" OR message CONTAINS "CMIO" OR message CONTAINS "sender")' --last 2m | tail -30

echo
echo "3. Check if extension process is running:"
ps aux | grep -i "GigECameraExtension" | grep -v grep || echo "Extension process not found"

echo
echo "4. Check for virtual camera errors:"
log show --predicate 'subsystem == "com.apple.cmio" AND message CONTAINS "GigE"' --last 2m | tail -20

echo
echo "5. Restart camera streaming:"
echo "   - In the app, click 'Hide Preview' then 'Show Preview' again"
echo "   - Or disconnect and reconnect the camera"
echo
echo "6. Force FaceTime to refresh cameras:"
echo "   - Quit FaceTime completely"
echo "   - Run: killall -9 cmioextensionmanagerd"
echo "   - Restart FaceTime"