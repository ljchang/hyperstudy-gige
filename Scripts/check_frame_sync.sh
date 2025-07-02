#!/bin/bash

echo "=== Checking Frame Synchronization ==="
echo ""

# Get current state
echo "1. Current shared data:"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null | grep -E "(IOSurfaceIDs|CurrentFrameIndex)" || echo "No data"

echo ""
echo "2. App writing to:"
log show --predicate 'eventMessage CONTAINS "Wrote frame" AND subsystem == "com.lukechang.GigEVirtualCamera"' --last 1m --info 2>/dev/null | grep -o "IOSurface: [0-9]*" | tail -5

echo ""
echo "3. Extension reading from:"
log show --predicate 'eventMessage CONTAINS "New frame" AND subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 1m --info 2>/dev/null | tail -5

echo ""
echo "4. Extension sending:"
log show --predicate 'eventMessage CONTAINS "Frame #" AND subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 1m --info 2>/dev/null | grep -o "IOSurface: [0-9]*" | tail -5