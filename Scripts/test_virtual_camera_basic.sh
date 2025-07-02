#!/bin/bash

echo "=== Basic Virtual Camera Test ==="
echo ""

# 1. Kill everything and start fresh
echo "1. Restarting everything..."
pkill -f "Photo Booth" 2>/dev/null
pkill -f GigEVirtualCamera.app 2>/dev/null
sleep 2

# 2. Start the app
echo "2. Starting GigEVirtualCamera app..."
open /Applications/GigEVirtualCamera.app
sleep 3

# 3. Check extension status
echo "3. Extension status:"
systemextensionsctl list 2>/dev/null | grep "com.lukechang.GigEVirtualCamera.Extension" | grep -E "activated enabled" | head -1

# 4. Open QuickTime instead of Photo Booth
echo ""
echo "4. Opening QuickTime Player..."
open -a "QuickTime Player"
sleep 2

echo ""
echo "5. In QuickTime Player:"
echo "   - Go to File → New Movie Recording"
echo "   - Click the down arrow next to record button"
echo "   - Select 'GigE Virtual Camera'"
echo "   - Do you see video?"
echo ""

# 5. Check if frames are being written
echo "6. Monitoring frame writes for 5 seconds..."
START=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
sleep 5
END=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
DIFF=$((END - START))

if [[ $DIFF -gt 0 ]]; then
    echo "   ✅ App is writing frames: $DIFF frames in 5s"
    echo "   "
    echo "   But if you see no video, the extension isn't reading them."
else
    echo "   ❌ App is NOT writing frames"
    echo "   "
    echo "   Make sure to click 'Show Preview' in the app!"
fi

echo ""
echo "7. Testing with simple camera app:"
open -a FaceTime
echo "   Can you select 'GigE Virtual Camera' in FaceTime?"