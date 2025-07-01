#!/bin/bash

echo "=== Debug Why Virtual Camera Not Found ==="
echo

# 1. Check if extension is running
echo "1. Extension process status:"
ps aux | grep -i "GigECameraExtension" | grep -v grep || echo "Not running"

# 2. List all CMIO devices with details
echo
echo "2. All CMIO devices:"
swift /Users/lukechang/Github/hyperstudy-gige/Scripts/list_cmio_devices.swift 2>&1 | grep -A2 -B2 "GigE"

# 3. Check timing issue
echo
echo "3. Let's wait and check again..."
sleep 3
echo "After 3 seconds:"
swift /Users/lukechang/Github/hyperstudy-gige/Scripts/list_cmio_devices.swift 2>&1 | grep "Name:" | grep -i "gige" || echo "Still not found"

# 4. Force camera app to request cameras
echo
echo "4. Opening camera app to trigger extension..."
open -a "Photo Booth"
sleep 2

# 5. Check again
echo
echo "5. After opening Photo Booth:"
ps aux | grep -i "GigECameraExtension" | grep -v grep || echo "Extension still not running"

echo
echo "6. The issue might be:"
echo "   - Extension takes time to register its device"
echo "   - App is checking too early before extension is ready"
echo "   - Need to delay CMIOFrameSender connection attempt"