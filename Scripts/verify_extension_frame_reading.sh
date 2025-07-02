#!/bin/bash

echo "=== Verifying Extension Frame Reading ==="
echo ""

# 1. Current frame index
CURRENT=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "1. Current frame index: $CURRENT"

# 2. Write a marker frame index
echo ""
echo "2. Writing marker frame index (99999)..."
defaults write ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 99999

# 3. Wait and see if it changes (app will overwrite if streaming)
sleep 2
NEW=$(defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
echo "   Frame index after 2s: $NEW"

if [[ $NEW -ne 99999 ]]; then
    echo "   ✅ App is actively writing frames (overwrote marker)"
else
    echo "   ⚠️  App is NOT writing frames"
fi

# 4. Check if extension modified any debug keys recently
echo ""
echo "3. Extension last activity:"
plutil -p ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist 2>/dev/null | grep "Debug_" | grep "2025-07-02 18"

# 5. Force a simple test
echo ""
echo "4. Testing direct IOSurface access:"
cat > /tmp/test_iosurface_simple.swift << 'EOF'
import Foundation
import IOSurface

let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera")
if let array = defaults?.array(forKey: "IOSurfaceIDs") {
    print("   IOSurface IDs: \(array)")
    if let firstID = (array.first as? NSNumber) {
        let id = IOSurfaceID(firstID.uint32Value)
        if let surface = IOSurfaceLookup(id) {
            print("   ✅ Can access IOSurface \(id)")
            print("   Size: \(IOSurfaceGetWidth(surface))x\(IOSurfaceGetHeight(surface))")
        } else {
            print("   ❌ Cannot access IOSurface \(id)")
        }
    }
}

let frameIndex = defaults?.integer(forKey: "currentFrameIndex") ?? 0
print("   Frame index: \(frameIndex)")
EOF

swift /tmp/test_iosurface_simple.swift 2>/dev/null

# 6. Monitor CMIO errors
echo ""
echo "5. Recent CMIO errors:"
log show --predicate 'process == "GigECameraExtension" AND messageType == error' --last 1m --style compact 2>/dev/null | grep -v "dealloc" | tail -5