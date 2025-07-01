#!/bin/bash

echo "=== Test Direct Sink Stream Connection ==="
echo

# Check if extension is running
echo "1. Extension process:"
ps aux | grep -i "GigECameraExtension" | grep -v grep | head -1

echo
echo "2. Virtual camera in system:"
system_profiler SPCameraDataType | grep -A3 "GigE"

echo
echo "3. The issue seems to be:"
echo "   - Virtual camera exists (we can see it in other apps)"
echo "   - Extension is running"
echo "   - But CMIOFrameSender can't find it"
echo
echo "Possible causes:"
echo "   - CMIOFrameSender is checking device names incorrectly"
echo "   - Timing issue with device enumeration"
echo "   - Need to use a different API to find the device"
echo
echo "Since the virtual camera IS working in other apps,"
echo "the extension is generating its test pattern correctly."
echo "We just need to fix the connection from app to extension."