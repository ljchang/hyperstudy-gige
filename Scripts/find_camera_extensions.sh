#!/bin/bash

echo "=== Finding Camera Extensions Settings ==="
echo

# 1. Check current macOS version
echo "1. macOS Version:"
sw_vers

echo
echo "2. Extension Status:"
systemextensionsctl list

echo
echo "3. Where to find Camera Extensions:"
echo "   macOS 13+: System Settings > Privacy & Security > Camera"
echo "   macOS 14+: System Settings > General > Login Items & Extensions > Camera Extensions"
echo

echo "4. Alternative locations to check:"
echo "   - System Settings > Privacy & Security > Extensions > Camera Extensions"
echo "   - System Settings > General > Login Items & Extensions"
echo

echo "5. Checking if extension needs user approval:"
log show --predicate 'process == "sysextd" AND message CONTAINS "waiting for user"' --last 10m | grep -i "gige" | tail -5

echo
echo "6. Force system to recognize camera extension:"
echo "   Try running this command in Terminal:"
echo "   sudo killall -9 cmioextensionmanagerd"
echo

echo "7. Check if camera is available to apps:"
# Check if any process can see the camera
ioreg -l | grep -i "CMIOExtension" | head -10