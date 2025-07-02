#!/bin/bash

echo "=== Debugging Virtual Camera Not Showing in Photo Booth ==="
echo ""

# Check system registration
echo "1. System camera registration:"
system_profiler SPCameraDataType 2>&1 | grep -A 3 "GigE Virtual Camera" || echo "Not found in system_profiler"

echo ""
echo "2. Extension process:"
ps aux | grep GigECameraExtension | grep -v grep || echo "Extension not running"

echo ""
echo "3. CMIO device check:"
# Use a simple test to see if CMIO can see the device
cat > /tmp/test_cmio.swift << 'EOF'
import CoreMediaIO
import Foundation

// Enable virtual cameras
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)
var allow: UInt32 = 1
CMIOObjectSetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &prop,
    0,
    nil,
    UInt32(MemoryLayout<UInt32>.size),
    &allow
)

// List devices
var propertyAddress = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
var dataUsed: UInt32 = 0
CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &propertyAddress, 0, nil, &dataSize)

let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
var devices = Array<CMIODeviceID>(repeating: 0, count: deviceCount)

CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &propertyAddress, 0, nil, dataSize, &dataUsed, &devices)

print("Found \(deviceCount) CMIO devices:")
for device in devices {
    var nameAddress = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    
    var nameSize: UInt32 = 0
    CMIOObjectGetPropertyDataSize(device, &nameAddress, 0, nil, &nameSize)
    
    if nameSize > 0 {
        var name: CFString = "" as CFString
        CMIOObjectGetPropertyData(device, &nameAddress, 0, nil, nameSize, &nameSize, &name)
        print("  - Device ID \(device): \(name)")
    }
}
EOF

swift /tmp/test_cmio.swift 2>&1 || echo "CMIO test failed"
rm -f /tmp/test_cmio.swift

echo ""
echo "4. Extension binary info:"
EXTENSION_PATH=$(find /Library/SystemExtensions -name "GigECameraExtension" -type f 2>/dev/null | grep -v "terminated" | head -1)
if [ -n "$EXTENSION_PATH" ]; then
    echo "Path: $EXTENSION_PATH"
    echo "Size: $(ls -lh "$EXTENSION_PATH" | awk '{print $5}')"
    echo "Date: $(ls -lh "$EXTENSION_PATH" | awk '{print $6, $7, $8}')"
else
    echo "Extension binary not found"
fi

echo ""
echo "5. Recent extension logs:"
log show --predicate 'subsystem CONTAINS "GigEVirtualCamera.Extension"' --last 2m --info 2>/dev/null | tail -10 || echo "No recent logs"

echo ""
echo "6. App Group data:"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || echo "No app group data"

echo ""
echo "7. Troubleshooting suggestions:"
echo "  - Try closing and reopening Photo Booth"
echo "  - Check if 'GigE Virtual Camera' appears in the camera dropdown"
echo "  - Try QuickTime Player > File > New Movie Recording"
echo "  - Restart the GigEVirtualCamera app"