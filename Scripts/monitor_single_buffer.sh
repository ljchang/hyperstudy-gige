#!/bin/bash

echo "=== Single Buffer Frame Flow Monitor ==="
echo "(Simplified to 1 IOSurface for debugging)"
echo ""

# 1. Check current state
echo "1. Current shared data:"
echo "   Frame index: $(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")"
echo "   IOSurface IDs: $(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist IOSurfaceIDs 2>/dev/null | tr -d '\n' | sed 's/[[:space:]]\+/ /g')"

# 2. Monitor frame flow
echo ""
echo "2. Frame flow (5 second test):"
START=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
sleep 5
END=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
DIFF=$((END - START))
echo "   Frames written: $DIFF ($(($DIFF / 5)) fps)"

if [[ $DIFF -eq 0 ]]; then
    echo ""
    echo "   ⚠️  No frames being written!"
    echo "   Action: Click 'Show Preview' in the app"
else
    echo "   ✅ App is streaming frames"
fi

# 3. Check extension stream state
echo ""
echo "3. Extension stream state:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND eventMessage CONTAINS "Stream started"' --last 2m --info --style compact 2>/dev/null | tail -1 || echo "   No stream start detected"

# 4. Monitor live logs
echo ""
echo "4. Live monitoring (press Ctrl+C to stop)..."
echo "   Time     | Frame Index | Event"
echo "   ---------|-------------|------"

# Start monitoring both frame index and logs
while true; do
    FRAME=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
    
    # Check for recent extension activity
    RECENT_LOG=$(log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND (eventMessage CONTAINS "New frame" OR eventMessage CONTAINS "Checking frame")' --last 2s --info --style compact 2>/dev/null | tail -1 | cut -d']' -f2- | xargs)
    
    if [[ -n "$RECENT_LOG" ]]; then
        printf "   %s | %-11s | %s\n" "$(date +%H:%M:%S)" "$FRAME" "$RECENT_LOG"
    else
        printf "   %s | %-11s | %s\n" "$(date +%H:%M:%S)" "$FRAME" "Waiting..."
    fi
    
    sleep 1
done