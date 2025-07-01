#!/bin/bash

echo "=== Debug Frame Streaming ==="
echo

# 1. Check if extension process is running
echo "1. Extension process:"
ps aux | grep -i "GigECameraExtension" | grep -v grep

echo
echo "2. Check if app is sending frames:"
log show --predicate 'process == "GigEVirtualCamera"' --last 2m | grep -i "frame\|cmio\|sender" | tail -20

echo
echo "3. Check extension logs:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 2m | tail -20

echo
echo "4. Common issues:"
echo "   - CMIOFrameSender not finding virtual camera device"
echo "   - Extension not receiving frames on sink stream"
echo "   - Frame format mismatch"
echo
echo "5. Try in the app:"
echo "   - Toggle 'Hide Preview' / 'Show Preview'"
echo "   - Disconnect and reconnect the camera"