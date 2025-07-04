#!/bin/bash

echo "=== Full Frame Flow Debug ==="
echo ""

# 1. Check if app is connected to sink
echo "1. App sink connection status:"
log show --style syslog --last 30s 2>/dev/null | grep -i "CMIOSinkConnector" | grep -E "(Successfully connected|Found device ID|Found sink stream|obtained buffer queue)" | tail -5

# 2. Check if app is sending frames
echo ""
echo "2. App frame sending:"
log show --style syslog --last 30s 2>/dev/null | grep -i "CMIOSinkConnector" | grep "Sent frame" | tail -3

# 3. Check extension activity
echo ""
echo "3. Extension activity:"
log show --style syslog --last 30s 2>/dev/null | grep "com.lukechang.GigEVirtualCamera.Extension" | grep -E "(Client connected|startStream|Received frame|Starting source)" | tail -10

# 4. Check if Photo Booth is connected
echo ""
echo "4. Client connections:"
log show --style syslog --last 1m 2>/dev/null | grep -E "(Photo Booth|QuickTime)" | grep -i "camera" | tail -5

# 5. Live monitoring
echo ""
echo "5. Starting live monitoring..."
echo "   - Open Photo Booth and select 'GigE Virtual Camera'"
echo "   - You should see activity below"
echo "   - Press Ctrl+C to stop"
echo ""

# Monitor multiple streams in parallel
(log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "CMIOSinkConnector"' | sed 's/^/[APP-SINK] /') &
PID1=$!

(log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category CONTAINS "Stream"' | sed 's/^/[EXT-STREAM] /') &
PID2=$!

(log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category == "Device"' | sed 's/^/[EXT-DEVICE] /') &
PID3=$!

# Trap to clean up background processes
trap "kill $PID1 $PID2 $PID3 2>/dev/null; exit" INT

# Wait
wait