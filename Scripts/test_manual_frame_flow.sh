#!/bin/bash

echo "=== Manual Frame Flow Test ==="
echo "Date: $(date)"
echo ""

# Kill any existing processes
echo "1. Killing existing processes..."
pkill -f GigEVirtualCamera.app || true
pkill -f GigECameraExtension || true
sleep 2

# Clear logs
echo "2. Clearing previous logs..."
log erase --all 2>/dev/null || true

# Start the app
echo "3. Starting GigEVirtualCamera app..."
open /Applications/GigEVirtualCamera.app

# Wait for app to start
sleep 3

# Check if IOSurface IDs are shared
echo "4. Checking shared IOSurface IDs..."
APP_GROUP="group.S368GH6KF7.com.lukechang.GigEVirtualCamera"
SURFACE_IDS=$(defaults read "$APP_GROUP" IOSurfaceIDs 2>/dev/null)
if [ -z "$SURFACE_IDS" ]; then
    echo "   ❌ No IOSurface IDs found in App Group"
else
    echo "   ✅ IOSurface IDs found: $SURFACE_IDS"
fi

# Manually trigger camera connection and streaming
echo "5. Triggering camera connection..."
osascript -e 'tell application "System Events"
    tell process "GigEVirtualCamera"
        set frontmost to true
        delay 1
        -- Click on the camera dropdown if needed
        -- Select Test Camera
        -- Click Connect button
    end tell
end tell' 2>/dev/null || echo "   (Manual UI interaction may be needed)"

# Monitor logs for 10 seconds
echo ""
echo "6. Monitoring frame flow for 10 seconds..."
echo "   Starting log capture..."

# Capture logs
LOGFILE="/tmp/manual_frame_test_$$.log"
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --info > "$LOGFILE" 2>&1 &
LOGPID=$!

sleep 10
kill $LOGPID 2>/dev/null

# Analyze logs
echo ""
echo "7. Log Analysis:"
echo ""
echo "   IOSurface Discovery:"
grep -E "(Discovered|IOSurface IDs|readSurfaceIDs)" "$LOGFILE" | head -10 | sed 's/^/   /'

echo ""
echo "   Frame Writing:"
grep -E "(writeFrame|Wrote frame|IOSurface: [0-9]+)" "$LOGFILE" | head -10 | sed 's/^/   /'

echo ""
echo "   Extension Activity:"
grep -E "(SharedMemoryFramePool|FrameCoordinator|Stream started)" "$LOGFILE" | head -10 | sed 's/^/   /'

echo ""
echo "   Errors:"
grep -i "error\|failed\|warning" "$LOGFILE" | head -10 | sed 's/^/   /'

# Check current shared data
echo ""
echo "8. Final shared data state:"
echo "   IOSurface IDs: $(defaults read "$APP_GROUP" IOSurfaceIDs 2>/dev/null || echo 'None')"
echo "   Current Frame Index: $(defaults read "$APP_GROUP" CurrentFrameIndex 2>/dev/null || echo 'None')"

# Cleanup
rm -f "$LOGFILE"

echo ""
echo "9. Next Steps:"
echo "   - If IOSurface IDs are not discovered, check timing/synchronization"
echo "   - If frames are not being written, check camera connection"
echo "   - Open Photo Booth and select 'GigE Virtual Camera' to test"