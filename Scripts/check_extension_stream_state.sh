#!/bin/bash

echo "=== Extension Stream State Check ==="
echo ""

# 1. Check if stream is selected in Photo Booth
echo "1. Checking if GigE Virtual Camera is selected in Photo Booth..."
system_profiler SPCameraDataType 2>/dev/null | grep -A5 "GigE Virtual Camera" || echo "   Camera not found in system"

# 2. Check frame flow
echo ""
echo "2. Frame flow check:"
FRAME1=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
sleep 2
FRAME2=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "   Frame index: $FRAME1 -> $FRAME2 (diff: $((FRAME2 - FRAME1)))"

# 3. Check extension initialization logs
echo ""
echo "3. Extension initialization (from shared data):"
plutil -p ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist 2>/dev/null | grep "Debug_" | head -5

# 4. Force a log entry by checking system extension state
echo ""
echo "4. System extension state:"
systemextensionsctl list 2>/dev/null | grep -A2 "com.lukechang.GigEVirtualCamera.Extension" || echo "   Extension not listed"

# 5. Check for any extension errors
echo ""
echo "5. Recent extension errors/warnings:"
log show --predicate 'process == "GigECameraExtension" AND (messageType == error OR messageType == fault)' --last 5m --style compact 2>/dev/null | tail -5 || echo "   No recent errors"

echo ""
echo "6. Try these steps:"
echo "   1. In Photo Booth: Make sure 'GigE Virtual Camera' is selected"
echo "   2. Try switching to another camera and back"
echo "   3. If still no logs, restart Photo Booth"