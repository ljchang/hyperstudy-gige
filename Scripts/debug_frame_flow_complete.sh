#!/bin/bash

echo "=== Complete Frame Flow Debug ==="
echo ""

# 1. App streaming check
echo "1. App streaming status:"
echo "   Checking if preview is showing..."
ps aux | grep GigEVirtualCamera.app | grep -v grep > /dev/null && echo "   ✅ App is running" || echo "   ❌ App not running"

# 2. Frame counter
echo ""
echo "2. Monitoring frame counter for 3 seconds:"
START=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "   Start: $START"
sleep 3
END=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "   End: $END"
DIFF=$((END - START))
echo "   Frames written: $DIFF"

if [[ $DIFF -eq 0 ]]; then
    echo ""
    echo "   ⚠️  NO FRAMES BEING WRITTEN!"
    echo ""
    echo "   Action needed in the app:"
    echo "   1. Make sure camera is connected (shows 'Connected' status)"
    echo "   2. Click 'Show Preview' button"
    echo "   3. You should see video in the preview window"
else
    echo ""
    echo "   ✅ App is writing frames ($((DIFF / 3)) fps)"
fi

# 3. Extension stream state
echo ""
echo "3. Extension stream logs (if any):"
log show --predicate 'process == "GigECameraExtension" AND (eventMessage CONTAINS "Stream" OR eventMessage CONTAINS "stream")' --last 30s --info --style compact 2>/dev/null | tail -5 || echo "   No stream logs"

# 4. Check for test pattern logs
echo ""
echo "4. Extension sending test pattern?"
log show --predicate 'process == "GigECameraExtension" AND eventMessage CONTAINS "test pattern"' --last 1m --info --style compact 2>/dev/null | tail -3 || echo "   No test pattern logs"

# 5. Direct process monitoring
echo ""
echo "5. Starting live log monitor for 10 seconds..."
echo "   (Looking for any extension activity)"
echo ""

gtimeout 10 log stream --predicate 'process == "GigECameraExtension"' --info --style compact 2>/dev/null || echo "   No live logs detected"