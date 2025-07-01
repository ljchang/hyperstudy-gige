#!/bin/bash

echo "Testing CMIO device discovery without sandboxing..."
echo ""

# Create a simple test program
cat > /tmp/test_cmio_discovery.swift << 'EOF'
import Foundation
import CoreMediaIO

// Enable virtual camera discovery
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var allow: UInt32 = 1
let enableResult = CMIOObjectSetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &prop,
    0,
    nil,
    UInt32(MemoryLayout<UInt32>.size),
    &allow
)

print("Enable virtual cameras result: \(enableResult)")

// Wait a moment
Thread.sleep(forTimeInterval: 1.0)

// Get device list size
var devicesProp = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
let sizeResult = CMIOObjectGetPropertyDataSize(
    CMIOObjectID(kCMIOObjectSystemObject),
    &devicesProp,
    0,
    nil,
    &dataSize
)

print("Get device list size result: \(sizeResult)")
print("Device list data size: \(dataSize) bytes")

if dataSize > 0 {
    let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
    print("Number of devices: \(deviceCount)")
    
    var devices = Array<CMIODeviceID>(repeating: 0, count: deviceCount)
    var dataUsed: UInt32 = 0
    
    let getResult = CMIOObjectGetPropertyData(
        CMIOObjectID(kCMIOObjectSystemObject),
        &devicesProp,
        0,
        nil,
        dataSize,
        &dataUsed,
        &devices
    )
    
    if getResult == 0 {
        for (index, device) in devices.enumerated() {
            print("Device \(index): ID = \(device)")
        }
    }
} else {
    print("ERROR: No devices found (dataSize = 0)")
}
EOF

echo "Running test..."
swift /tmp/test_cmio_discovery.swift

echo ""
echo "Cleaning up..."
rm -f /tmp/test_cmio_discovery.swift