#!/bin/bash

echo "=== Forcing Extension Activity ==="
echo ""

# 1. Check extension PID
PID=$(ps aux | grep GigECameraExtension | grep -v grep | awk '{print $2}')
echo "1. Extension PID: $PID"

# 2. Monitor all logs from this PID
echo ""
echo "2. All logs from extension process (10 seconds):"
if [[ -n "$PID" ]]; then
    gtimeout 10 log stream --predicate "processID == $PID" --info --style compact || echo "No logs detected"
else
    echo "Extension not running"
fi

# 3. Check if extension created IOSurfaces
echo ""
echo "3. Extension IOSurface creation time:"
plutil -p ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist 2>/dev/null | grep "Debug_PoolInit"

# 4. Test IOSurface access
echo ""
echo "4. Testing IOSurface access from extension's perspective:"
cat > /tmp/test_extension_surface.swift << 'EOF'
import Foundation
import IOSurface

// Read the shared IOSurface ID
let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera")
if let idArray = defaults?.array(forKey: "IOSurfaceIDs") as? [NSNumber],
   let firstID = idArray.first {
    let surfaceID = IOSurfaceID(firstID.uint32Value)
    print("   IOSurface ID: \(surfaceID)")
    
    // Try to access it
    if let surface = IOSurfaceLookup(surfaceID) {
        let width = IOSurfaceGetWidth(surface)
        let height = IOSurfaceGetHeight(surface)
        print("   ✅ Can access IOSurface: \(width)x\(height)")
        
        // Check if it's being updated
        IOSurfaceLock(surface, .readOnly, nil)
        if let baseAddr = IOSurfaceGetBaseAddress(surface) {
            // Sample a pixel to see if content changes
            let pixelData = baseAddr.assumingMemoryBound(to: UInt32.self)
            let firstPixel = pixelData[0]
            print("   First pixel value: 0x\(String(format: "%08X", firstPixel))")
        }
        IOSurfaceUnlock(surface, .readOnly, nil)
    } else {
        print("   ❌ Cannot access IOSurface \(surfaceID)")
    }
} else {
    print("   ❌ No IOSurface IDs found")
}

// Check frame index
let frameIndex = defaults?.integer(forKey: "currentFrameIndex") ?? 0
print("   Current frame index: \(frameIndex)")
EOF

swift /tmp/test_extension_surface.swift 2>/dev/null