#!/bin/bash

echo "=== Debugging Photo Booth Connection ==="
echo ""

# Check Photo Booth process
echo "1. Photo Booth status:"
ps aux | grep -i "photo booth" | grep -v grep || echo "Photo Booth not running"

echo ""
echo "2. Recent extension connections:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category == "Provider"' --last 2m --info 2>/dev/null | grep -E "(Client|connected|disconnected)" | tail -10

echo ""
echo "3. Recent stream activity:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category == "StreamSource"' --last 2m --info 2>/dev/null | grep -E "(Stream|started|stopped)" | tail -10

echo ""
echo "4. Testing with system_profiler:"
system_profiler SPCameraDataType | grep -A 3 "GigE Virtual Camera"

echo ""
echo "5. Force stream start..."
# Try to trigger stream by accessing camera info
/usr/bin/osascript -e 'tell application "Photo Booth" to activate' 2>/dev/null

echo ""
echo "Monitoring for 10 seconds..."
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --info --style compact | grep -E "(Client|Stream|started|Checking|frame)" &
LOGPID=$!
sleep 10
kill $LOGPID 2>/dev/null

echo ""
echo "If no activity shown:"
echo "- Make sure 'GigE Virtual Camera' is selected in Photo Booth"
echo "- Try switching to another camera and back"
echo "- Check if privacy settings allow camera access"