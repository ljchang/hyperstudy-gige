#\!/bin/bash

echo "=== Diagnosing GigE Virtual Camera Frame Flow ==="
echo "Date: $(date)"
echo ""

# Check if app and extension are running
echo "1. Checking processes..."
echo "   App: $(ps aux | grep -i "[G]igEVirtualCamera.app" | wc -l) instance(s)"
echo "   Extension: $(ps aux | grep -i "[G]igECameraExtension" | wc -l) instance(s)"
echo "   Photo Booth: $(ps aux | grep -i "[P]hoto Booth" | wc -l) instance(s)"
echo ""

# Check system extension status
echo "2. Checking system extension..."
systemextensionsctl list | grep -A 2 "com.lukechang.GigEVirtualCamera" || echo "   Extension not found in system list"
echo ""

# Check virtual camera in system
echo "3. Checking camera availability..."
system_profiler SPCameraDataType | grep -A 5 "GigE Virtual Camera" || echo "   Virtual camera not found in system"
echo ""

# Check app group shared data
echo "4. Checking shared UserDefaults..."
APP_GROUP_PATH="$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera"
if [ -d "$APP_GROUP_PATH" ]; then
    echo "   App group directory exists"
    PLIST_PATH="$APP_GROUP_PATH/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist"
    if [ -f "$PLIST_PATH" ]; then
        echo "   Shared preferences file exists"
        # Try to read current frame info
        defaults read "$APP_GROUP_PATH/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera" 2>/dev/null | grep -E "(currentFrameIndex|currentFrameSurfaceID|frameWidth|frameHeight)" || echo "   No frame data in shared defaults"
    else
        echo "   Shared preferences file NOT found"
    fi
else
    echo "   App group directory NOT found"
fi
echo ""

# Monitor logs for 5 seconds
echo "5. Monitoring frame flow for 5 seconds..."
echo "   (Legend: APP=writes, CACHE=reads, STREAM=sends)"
echo ""

# Create a temporary file for log capture
LOGFILE="/tmp/frame_flow_test_$$.log"

# Start log stream in background
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' --style compact > "$LOGFILE" 2>&1 &
LOGPID=$\!

# Wait 5 seconds
sleep 5

# Kill log stream
kill $LOGPID 2>/dev/null

# Analyze captured logs
echo "   Frame flow analysis:"
APP_WRITES=$(grep "📤 Wrote frame" "$LOGFILE" 2>/dev/null | wc -l | tr -d ' ')
EXT_READS=$(grep "📥 Cached frame" "$LOGFILE" 2>/dev/null | wc -l | tr -d ' ')
EXT_SENDS=$(grep "📤 Frame #" "$LOGFILE" 2>/dev/null | wc -l | tr -d ' ')

echo "   - App wrote $APP_WRITES frames"
echo "   - Extension cached $EXT_READS frames"
echo "   - Extension sent $EXT_SENDS frames"

# Show sample of recent IOSurface IDs
echo ""
echo "   Recent IOSurface IDs:"
grep -oE "IOSurface: [0-9]+" "$LOGFILE" 2>/dev/null | tail -5 | sed 's/^/   /'

# Clean up
rm -f "$LOGFILE"

echo ""
echo "6. Diagnosis:"
if [ "$APP_WRITES" -gt 0 ] && [ "$EXT_READS" -eq 0 ]; then
    echo "   ❌ App is writing frames, but extension is NOT reading them"
    echo "   Possible issues:"
    echo "   - Extension not polling UserDefaults"
    echo "   - App group permissions issue"
    echo "   - Extension stream not started"
elif [ "$EXT_READS" -gt 0 ] && [ "$EXT_SENDS" -eq 0 ]; then
    echo "   ❌ Extension is reading frames, but NOT sending them"
    echo "   Possible issues:"
    echo "   - Timer not running"
    echo "   - Stream not properly started"
    echo "   - Sample buffer creation failing"
elif [ "$APP_WRITES" -eq 0 ]; then
    echo "   ❌ App is NOT writing any frames"
    echo "   Possible issues:"
    echo "   - Camera not connected/streaming"
    echo "   - IOSurfaceFrameWriter not initialized"
    echo "   - Frames not IOSurface-backed"
elif [ "$EXT_SENDS" -gt 0 ]; then
    echo "   ✅ Complete frame flow detected\!"
    echo "   If Photo Booth still shows no video:"
    echo "   - Check Photo Booth camera selection"
    echo "   - Try restarting Photo Booth"
    echo "   - Check for format compatibility issues"
else
    echo "   ⚠️  No frame activity detected"
    echo "   - Make sure camera is connected and streaming"
    echo "   - Check if extension is properly loaded"
fi
