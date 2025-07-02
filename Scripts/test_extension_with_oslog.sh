#!/bin/bash

echo "=== Testing Extension with os_log ==="
echo ""

# 1. First, make sure preview is active in the app
echo "1. In the GigEVirtualCamera app:"
echo "   - Make sure camera shows 'Connected'"
echo "   - Click 'Show Preview' button"
echo "   - You should see video in the preview"
echo ""

# 2. Check if frames are being written
echo "2. Checking frame writes..."
FRAME1=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
sleep 2
FRAME2=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")

if [[ $FRAME2 -gt $FRAME1 ]]; then
    echo "   ✅ Frames are being written ($FRAME1 -> $FRAME2)"
else
    echo "   ❌ No frames being written. Click 'Show Preview' in the app!"
    exit 1
fi

# 3. Now test in Photo Booth
echo ""
echo "3. In Photo Booth:"
echo "   - Select 'GigE Virtual Camera' from camera menu"
echo "   - This should trigger startStream() in the extension"
echo ""

# 4. Monitor all extension activity
echo "4. Monitoring extension (PID: $(ps aux | grep GigECameraExtension | grep -v grep | awk '{print $2}'))..."
echo ""

# Try different log predicates
echo "Trying different log queries:"
echo ""

echo "a) By process name:"
log show --predicate 'process == "GigECameraExtension"' --last 30s --info 2>/dev/null | tail -5

echo ""
echo "b) By subsystem:"
log show --predicate 'subsystem CONTAINS "GigEVirtualCamera"' --last 30s --info 2>/dev/null | tail -5

echo ""
echo "c) By any message with our keywords:"
log show --predicate 'eventMessage CONTAINS "GigE" OR eventMessage CONTAINS "IOSurface" OR eventMessage CONTAINS "Stream"' --last 30s --info 2>/dev/null | grep -i gige | tail -5

echo ""
echo "5. If you see no logs, the extension logging is not working."
echo "   But the extension IS running (we can see the IOSurface was created)."