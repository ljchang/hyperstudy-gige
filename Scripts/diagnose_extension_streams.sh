#!/bin/bash

echo "=== Diagnosing Extension Stream Issues ==="
echo ""

# Check if extension is running
EXT_PID=$(ps aux | grep GigECameraExtension | grep -v grep | awk '{print $2}')
if [ -z "$EXT_PID" ]; then
    echo "❌ Extension is NOT running!"
    exit 1
fi

echo "✅ Extension is running (PID: $EXT_PID)"
echo ""

# Check UserDefaults for debug markers
echo "📋 Extension Debug Markers:"
defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist | grep -E "Debug_|StreamState"

echo ""
echo "🔍 Looking for recent extension activity..."

# Use log show with simpler predicate
echo "Recent extension logs:"
log show --last 1m --process $EXT_PID 2>/dev/null | tail -20

echo ""
echo "📊 System Extension Status:"
systemextensionsctl list | grep -A2 "com.lukechang.GigEVirtualCamera"

echo ""
echo "🎥 Virtual Camera in System:"
system_profiler SPCameraDataType | grep -A5 "GigE Virtual Camera"

echo ""
echo "🔌 Testing CMIO Device Discovery..."
# Run swift script to check CMIO
cat > /tmp/test_cmio.swift << 'EOF'
import CoreMediaIO
import Foundation

// Enable device discovery
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)
var allow: UInt32 = 1
CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, UInt32(MemoryLayout<UInt32>.size), &allow)

// Get all devices
var dataSize: UInt32 = 0
var devices: [CMIOObjectID] = []

var address = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, &dataSize)
let deviceCount = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
devices = Array(repeating: 0, count: deviceCount)

CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, dataSize, &dataSize, &devices)

// Check for our device
var found = false
for device in devices {
    var uidAddress = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    
    var uidSize: UInt32 = 0
    CMIOObjectGetPropertyDataSize(device, &uidAddress, 0, nil, &uidSize)
    
    if uidSize > 0 {
        let uidData = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
        defer { uidData.deallocate() }
        
        CMIOObjectGetPropertyData(device, &uidAddress, 0, nil, uidSize, &uidSize, uidData)
        
        if let uid = uidData.pointee as String? {
            if uid.contains("4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4") {
                print("✅ Found GigE Virtual Camera device!")
                found = true
                
                // Check streams
                var streamsAddress = CMIOObjectPropertyAddress(
                    mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyStreams),
                    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
                )
                
                var streamsSize: UInt32 = 0
                CMIOObjectGetPropertyDataSize(device, &streamsAddress, 0, nil, &streamsSize)
                
                let streamCount = Int(streamsSize) / MemoryLayout<CMIOStreamID>.size
                print("  Stream count: \(streamCount)")
            }
        }
    }
}

if !found {
    print("❌ GigE Virtual Camera device NOT found in CMIO!")
}
EOF

swift /tmp/test_cmio.swift
rm -f /tmp/test_cmio.swift

echo ""
echo "✅ Diagnostic complete!"