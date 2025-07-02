#!/bin/bash

echo "=== Debug Stream Status ==="
echo ""

# 1. Check all debug markers
echo "1. Debug markers in shared data:"
plutil -p ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist 2>/dev/null | grep "Debug_" | sort

# 2. Check IOSurface
echo ""
echo "2. IOSurface status:"
IOSURFACE_IDS=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist IOSurfaceIDs 2>/dev/null)
echo "   IOSurface IDs: $IOSURFACE_IDS"

# 3. Check frame index
echo ""
echo "3. Frame flow:"
FRAME=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "   Current frame: $FRAME"

# 4. Process status
echo ""
echo "4. Process status:"
echo "   App: $(ps aux | grep GigEVirtualCamera.app | grep -v grep > /dev/null && echo "✅ Running" || echo "❌ Not running")"
echo "   Extension: $(ps aux | grep GigECameraExtension | grep -v grep > /dev/null && echo "✅ Running" || echo "❌ Not running")"
echo "   Photo Booth: $(ps aux | grep "Photo Booth" | grep -v grep > /dev/null && echo "✅ Running" || echo "❌ Not running")"

# 5. Instructions
echo ""
echo "5. Test sequence:"
echo "   a) Update the app: rm -rf /Applications/GigEVirtualCamera.app && cp -R /Users/lukechang/Github/hyperstudy-gige/build/Debug/GigEVirtualCamera.app /Applications/"
echo "   b) Open the app and reinstall extension"
echo "   c) Click 'Show Preview' in the app"
echo "   d) In Photo Booth, select 'GigE Virtual Camera'"
echo "   e) Run this script again to see if 'Debug_StreamStarted' appears"