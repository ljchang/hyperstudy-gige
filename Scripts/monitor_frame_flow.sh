#\!/bin/bash

echo "=== Monitoring Frame Flow ==="
echo "Press Ctrl+C to stop"
echo ""

# Monitor multiple streams in parallel
echo "Starting monitors..."

# 1. Extension stream state signals
(log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category == "StreamState"' | sed 's/^/[EXT-STATE] /') &
PID1=$\!

# 2. App sink connector
(log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "CMIOSinkConnector"' | sed 's/^/[APP-SINK] /') &
PID2=$\!

# 3. Extension sink/source activity  
(log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND (category == "SinkStream" OR category == "SourceStream")' | sed 's/^/[EXT-STREAM] /') &
PID3=$\!

# 4. App camera manager
(log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "CameraManager" AND message CONTAINS "handleStreamStateChange"' | sed 's/^/[APP-MGR] /') &
PID4=$\!

# 5. Frame counts
(log stream --predicate 'message CONTAINS "frame" AND (message CONTAINS "Sent" OR message CONTAINS "Received")' | grep -E "(Sent frame|Received frame)" | sed 's/^/[FRAMES] /') &
PID5=$\!

# Trap to clean up
trap "kill $PID1 $PID2 $PID3 $PID4 $PID5 2>/dev/null; exit" INT

# Show current state
echo ""
echo "Current App Group state:"
plutil -p "$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist" 2>/dev/null | grep -A3 StreamState

echo ""
echo "Monitoring... (open Photo Booth and select GigE Virtual Camera)"
echo ""

wait
