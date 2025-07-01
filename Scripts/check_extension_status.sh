#!/bin/bash

echo "=== Checking Extension Status ==="
echo

# 1. Check system extensions
echo "1. System Extensions Status:"
systemextensionsctl list

echo
echo "2. Check if virtual camera appears in system:"
system_profiler SPCameraDataType | grep -A5 "GigE" || echo "No GigE Virtual Camera found in system cameras"

echo
echo "3. Check CMIO devices:"
# Try to list CMIO devices using ioreg
ioreg -l -w 0 | grep -i "gige" | head -10

echo
echo "4. Check if extension is running:"
ps aux | grep -i "gigecameraextension" | grep -v grep || echo "Extension process not found"

echo
echo "5. Recent extension logs:"
log show --predicate 'process == "GigECameraExtension" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 5m | tail -20

echo
echo "6. Test in QuickTime:"
echo "   - Open QuickTime Player"
echo "   - File → New Movie Recording"
echo "   - Click dropdown next to record button"
echo "   - Look for 'GigE Virtual Camera'"