#!/bin/bash

echo "=== Live Frame Flow Monitor ==="
echo ""

# Check if streaming is active
echo "1. Checking app status..."
ps aux | grep GigEVirtualCamera.app | grep -v grep > /dev/null && echo "✅ App is running" || echo "❌ App not running"

echo ""
echo "2. Current frame state:"
FRAME_INDEX=$(defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "   Frame index: $FRAME_INDEX"

echo ""
echo "3. Monitoring frame flow (press Ctrl+C to stop)..."
echo ""
echo "Time       | Frame Index | IOSurface IDs"
echo "-----------|-------------|------------------"

while true; do
    FRAME=$(defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
    IDS=$(defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist IOSurfaceIDs 2>/dev/null | tr -d '\n' | sed 's/[[:space:]]\+/ /g' | cut -c1-30)
    printf "%s | %-11s | %s\n" "$(date +%H:%M:%S)" "$FRAME" "$IDS"
    sleep 1
done