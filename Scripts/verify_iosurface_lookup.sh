#!/bin/bash

echo "=== IOSurface Lookup Verification ==="
echo ""

# Get the IOSurface IDs from shared data
echo "1. Extension's IOSurface IDs:"
defaults read /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist IOSurfaceIDs 2>/dev/null

echo ""
echo "2. Checking if app can write to these surfaces..."

# Create a simple test program to verify IOSurface lookup
cat > /tmp/test_iosurface.swift << 'EOF'
import Foundation
import IOSurface

let surfaceIDs: [IOSurfaceID] = [1657, 1678, 1679]

for id in surfaceIDs {
    if let surface = IOSurfaceLookup(id) {
        let width = IOSurfaceGetWidth(surface)
        let height = IOSurfaceGetHeight(surface)
        print("✅ IOSurface \(id): \(width)x\(height)")
    } else {
        print("❌ IOSurface \(id): lookup failed")
    }
}
EOF

echo ""
swift /tmp/test_iosurface.swift 2>/dev/null || echo "Failed to test IOSurface lookup"

echo ""
echo "3. Check if app is connecting to camera:"
ps aux | grep GigEVirtualCamera.app | grep -v grep > /dev/null && echo "✅ App is running" || echo "❌ App not running"

echo ""
echo "4. Clear old frame index to trigger new writes:"
defaults write /Users/lukechang/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist currentFrameIndex 0
echo "✅ Reset frame index to 0"