#!/bin/bash

echo "=== Triggering Frame Flow ==="
echo ""

# 1. Check current state
echo "1. Current state:"
FRAME_INDEX=$(defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "   Frame index: $FRAME_INDEX"

# 2. Force frame index update to trigger extension
echo ""
echo "2. Triggering frame write..."
defaults write /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 1

# 3. Monitor for 5 seconds
echo ""
echo "3. Monitoring frame flow for 5 seconds..."
echo "   Time | Frame Index"
echo "   -----|------------"
for i in {1..5}; do
    FRAME=$(defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
    printf "   %d sec | %s\n" "$i" "$FRAME"
    sleep 1
done

# 4. Check if extension is reading
echo ""
echo "4. Checking extension activity..."
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 10s --info --style compact 2>/dev/null | grep -E "(New frame|Checking frame)" | tail -5 || echo "   No frame activity detected"

echo ""
echo "5. IMPORTANT: In the GigEVirtualCamera app:"
echo "   - Make sure 'Test Camera (Aravis Simulator)' is selected"
echo "   - Click 'Connect' button"
echo "   - Click 'Start Streaming' button"
echo "   - You should see the preview updating"