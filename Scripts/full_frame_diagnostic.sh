#!/bin/bash

echo "=== Full Frame Flow Diagnostic ==="
echo "Time: $(date)"
echo ""

# 1. Process status
echo "1. PROCESS STATUS:"
echo "   App: $(ps aux | grep GigEVirtualCamera.app | grep -v grep > /dev/null && echo "✅ Running" || echo "❌ Not running")"
echo "   Extension: $(ps aux | grep GigECameraExtension | grep -v grep > /dev/null && echo "✅ Running" || echo "❌ Not running")"
echo "   Photo Booth: $(ps aux | grep "Photo Booth" | grep -v grep > /dev/null && echo "✅ Running" || echo "❌ Not running")"

# 2. Shared data
echo ""
echo "2. SHARED DATA:"
FRAME_INDEX=$(defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
IOSURFACE_IDS=$(defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist IOSurfaceIDs 2>/dev/null | tr -d '\n' | sed 's/[[:space:]]\+/ /g')
echo "   Current frame index: $FRAME_INDEX"
echo "   IOSurface IDs: $IOSURFACE_IDS"

# 3. Frame rate check
echo ""
echo "3. FRAME RATE CHECK (5 second sample):"
START_FRAME=$FRAME_INDEX
sleep 5
END_FRAME=$(defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 2>/dev/null || echo "0")
FRAMES_WRITTEN=$((END_FRAME - START_FRAME))
FPS=$((FRAMES_WRITTEN / 5))
echo "   Frames written in 5s: $FRAMES_WRITTEN"
echo "   Approximate FPS: $FPS"

# 4. Recent logs
echo ""
echo "4. RECENT APP ACTIVITY (last 10 seconds):"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "IOSurfaceFrameWriter"' --last 10s --info --style compact 2>/dev/null | grep "Wrote frame" | tail -3 || echo "   No recent frame writes logged"

echo ""
echo "5. RECENT EXTENSION ACTIVITY (last 10 seconds):"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 10s --info --style compact 2>/dev/null | grep -E "(Stream|frame|Frame)" | tail -5 || echo "   No recent extension activity"

# 5. IOSurface validation
echo ""
echo "6. IOSURFACE VALIDATION:"
cat > /tmp/validate_surfaces.swift << 'EOF'
import Foundation
import IOSurface

// Read surface IDs from shared data
let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera")
if let idArray = defaults?.array(forKey: "IOSurfaceIDs") as? [NSNumber] {
    let surfaceIDs = idArray.map { IOSurfaceID($0.uint32Value) }
    print("   Found \(surfaceIDs.count) IOSurface IDs")
    
    for (index, id) in surfaceIDs.enumerated() {
        if let surface = IOSurfaceLookup(id) {
            let width = IOSurfaceGetWidth(surface)
            let height = IOSurfaceGetHeight(surface)
            print("   ✅ Surface \(index) (ID: \(id)): \(width)x\(height)")
        } else {
            print("   ❌ Surface \(index) (ID: \(id)): Lookup failed")
        }
    }
} else {
    print("   ❌ No IOSurface IDs found in shared data")
}
EOF
swift /tmp/validate_surfaces.swift 2>/dev/null || echo "   Failed to validate surfaces"

echo ""
echo "7. RECOMMENDATIONS:"
if [[ $FPS -gt 20 ]]; then
    echo "   ✅ App is writing frames at good rate ($FPS fps)"
else
    echo "   ⚠️  App frame rate is low ($FPS fps)"
fi

# Check if we need to restart extension
LAST_EXTENSION_LOG=$(log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 30s --info 2>/dev/null | wc -l)
if [[ $LAST_EXTENSION_LOG -lt 5 ]]; then
    echo "   ⚠️  Extension appears inactive - try selecting camera in Photo Booth"
    echo "   ⚠️  Or uninstall/reinstall extension in the app"
else
    echo "   ✅ Extension appears active"
fi