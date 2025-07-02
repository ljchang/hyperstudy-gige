#!/bin/bash

echo "=== IOSurface Synchronization Check ==="
echo ""

# 1. Get extension's IOSurfaces
echo "1. Extension's IOSurfaces:"
defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist IOSurfaceIDs 2>/dev/null

# 2. Check if app has discovered them
echo ""
echo "2. Checking app's IOSurface discovery..."
cat > /tmp/check_app_surfaces.swift << 'EOF'
import Foundation
import IOSurface

// Check what the app sees
let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera")
if let idArray = defaults?.array(forKey: "IOSurfaceIDs") as? [NSNumber] {
    let surfaceIDs = idArray.map { IOSurfaceID($0.uint32Value) }
    print("App sees \(surfaceIDs.count) surfaces: \(surfaceIDs)")
    
    // Try to write to first surface
    if let firstID = surfaceIDs.first,
       let surface = IOSurfaceLookup(firstID) {
        print("✅ App can access surface \(firstID)")
        
        // Check if it's writable
        IOSurfaceLock(surface, [], nil)
        let baseAddr = IOSurfaceGetBaseAddress(surface)
        if baseAddr != nil {
            print("✅ Surface is writable")
        } else {
            print("❌ Cannot get base address")
        }
        IOSurfaceUnlock(surface, [], nil)
    }
} else {
    print("❌ No IOSurface IDs in shared data")
}

// Check frame index
let frameIndex = defaults?.integer(forKey: "currentFrameIndex") ?? -1
print("\nCurrent frame index: \(frameIndex)")
EOF

swift /tmp/check_app_surfaces.swift 2>/dev/null

# 3. Check if processes need restart
echo ""
echo "3. Process check:"
ps aux | grep GigEVirtualCamera.app | grep -v grep > /dev/null && echo "✅ App running" || echo "❌ App not running"
ps aux | grep GigECameraExtension | grep -v grep > /dev/null && echo "✅ Extension running" || echo "❌ Extension not running"

# 4. Try to trigger frame write
echo ""
echo "4. Attempting to trigger frame write..."
# Clear frame index to 0 to trigger extension to think there's no frames yet
defaults write /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 0
echo "Reset frame index to 0"

echo ""
echo "5. Recommendations:"
echo "   - Make sure 'Test Camera' is selected and connected in the app"
echo "   - Click 'Start Streaming' if not already streaming"
echo "   - Check that Photo Booth has 'GigE Virtual Camera' selected"