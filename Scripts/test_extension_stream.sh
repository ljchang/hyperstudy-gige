#!/bin/bash

echo "=== Testing Camera Extension Stream ==="
echo ""

# Check if Photo Booth is using the virtual camera
echo "1. Checking Photo Booth camera selection..."
PHOTO_BOOTH_PID=$(pgrep "Photo Booth")
if [ -n "$PHOTO_BOOTH_PID" ]; then
    echo "   Photo Booth is running (PID: $PHOTO_BOOTH_PID)"
    
    # Check if virtual camera is being accessed
    lsof -p "$PHOTO_BOOTH_PID" 2>/dev/null | grep -i "extension\|camera" | head -5
else
    echo "   Photo Booth is not running"
fi
echo ""

# Monitor extension activity
echo "2. Monitoring extension activity for 10 seconds..."
echo "   Looking for stream start/stop events..."
echo ""

# Capture logs
LOGFILE="/tmp/extension_test_$$.log"
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --style compact > "$LOGFILE" 2>&1 &
LOGPID=$!

# Wait
sleep 10

# Kill log stream
kill $LOGPID 2>/dev/null

# Analyze
echo "3. Analysis:"
STREAM_STARTS=$(grep -c "Stream started" "$LOGFILE" 2>/dev/null || echo "0")
STREAM_STOPS=$(grep -c "Stream stopped" "$LOGFILE" 2>/dev/null || echo "0")
FRAMES_SENT=$(grep -c "Zero-copy" "$LOGFILE" 2>/dev/null || echo "0")
TIMER_EVENTS=$(grep -c "sendNextFrame" "$LOGFILE" 2>/dev/null || echo "0")

echo "   - Stream start events: $STREAM_STARTS"
echo "   - Stream stop events: $STREAM_STOPS"
echo "   - Frames sent: $FRAMES_SENT"
echo "   - Timer events: $TIMER_EVENTS"
echo ""

# Show any errors
echo "4. Recent errors/warnings:"
grep -E "(error|Error|failed|Failed|warning|Warning)" "$LOGFILE" 2>/dev/null | tail -10 | sed 's/^/   /'

# Clean up
rm -f "$LOGFILE"

echo ""
echo "5. Try these steps:"
echo "   1. In Photo Booth, go to Camera menu"
echo "   2. Select 'GigE Virtual Camera'"
echo "   3. The extension stream should start automatically"
echo ""
echo "   If the camera doesn't appear:"
echo "   - Restart Photo Booth"
echo "   - Run: systemextensionsctl reset"
echo "   - Reinstall the app"