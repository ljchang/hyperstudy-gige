#!/bin/bash

echo "=== Frame Flow Diagnostics ==="
echo ""

# 1. Check shared data
echo "1. Shared data state:"
defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist 2>/dev/null | grep -E "(IOSurfaceIDs|CurrentFrameIndex|currentFrameIndex)" || echo "No data found"

echo ""
echo "2. Check if app is writing frames:"
# Monitor for 5 seconds
timeout 5 log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "IOSurfaceFrameWriter"' --info --style compact 2>/dev/null | grep -E "(Wrote frame|writeFrame)" || echo "No frame writes detected"

echo ""
echo "3. Check if extension is polling:"
timeout 5 log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category == "StreamSource"' --info --style compact 2>/dev/null | grep -E "(Checking frame|New frame|No new frame)" || echo "No extension activity detected"

echo ""
echo "4. Process status:"
ps aux | grep -E "GigEVirtualCamera|GigECameraExtension" | grep -v grep | awk '{print $11}' | while read proc; do
    echo "  - $(basename "$proc"): Running"
done

echo ""
echo "5. IOSurface validation:"
# Check if IOSurfaces are valid
if command -v ioreg &> /dev/null; then
    ioreg -l | grep -c IOSurface | xargs echo "  - Total IOSurfaces in system:"
fi