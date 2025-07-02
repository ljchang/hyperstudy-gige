#!/bin/bash

echo "=== Extension Activity Monitor ==="
echo ""

# 1. Check shared data
echo "1. Shared data state:"
plutil -p ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist 2>/dev/null | grep -E "(currentFrameIndex|IOSurfaceIDs)" | head -10

# 2. Clean up old key
echo ""
echo "2. Cleaning up old uppercase key..."
defaults delete ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist CurrentFrameIndex 2>/dev/null || true

# 3. Monitor frame index changes
echo ""
echo "3. Monitoring frame index (5 second sample):"
START=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "   Start: $START"
sleep 5
END=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "   End: $END"
echo "   Frames in 5s: $((END - START))"

# 4. Check extension process
echo ""
echo "4. Extension process:"
ps aux | grep GigECameraExtension | grep -v grep | awk '{print "   PID:", $2, "CPU:", $3"%", "Started:", $9}'

# 5. Monitor all extension logs
echo ""
echo "5. Extension logs (last 30 seconds):"
log show --predicate 'process == "GigECameraExtension"' --last 30s --info --style compact 2>/dev/null | tail -20 || echo "   No recent logs"

# 6. Monitor specific subsystem
echo ""
echo "6. Extension subsystem logs:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 30s --info --style compact 2>/dev/null | grep -v "Debug_" | tail -10 || echo "   No subsystem logs"

# 7. Live monitoring
echo ""
echo "7. Starting live monitor (press Ctrl+C to stop)..."
echo "   Watching for: frame activity, stream events, errors"
echo ""

log stream --predicate 'process == "GigECameraExtension" OR (subsystem == "com.lukechang.GigEVirtualCamera.Extension")' --info --style compact