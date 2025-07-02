#!/bin/bash

echo "=== Debugging Sink Stream Discovery ==="
echo
echo "1. Checking if extension is loaded..."
systemextensionsctl list | grep -i gige

echo
echo "2. Checking for sink stream in CMIO devices..."
echo "Running CMIO device enumeration..."

# Create a Swift script to enumerate CMIO devices and their streams
cat > /tmp/enumerate_cmio_streams.swift << 'EOF'
import Foundation
import CoreMediaIO

// Enable CMIO DAL to see our extension
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

// Get all devices
var dataSize: UInt32 = 0
var devices: [CMIOObjectID] = []

prop.mSelector = CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices)
CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, &dataSize)

let deviceCount = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
devices = Array(repeating: 0, count: deviceCount)

CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, dataSize, &dataSize, &devices)

print("\nFound \(deviceCount) CMIO devices:")

for device in devices where device != 0 {
    // Get device name
    var name = "" as CFString
    var nameSize = UInt32(MemoryLayout<CFString>.size)
    prop.mSelector = CMIOObjectPropertySelector(kCMIOObjectPropertyName)
    
    if CMIOObjectGetPropertyData(device, &prop, 0, nil, nameSize, &nameSize, &name) == noErr {
        print("\nDevice: \(name)")
        
        // Check if this is our GigE Virtual Camera
        if (name as String).contains("GigE") {
            print("  ✅ Found GigE Virtual Camera!")
            
            // Get all streams for this device
            var streamsProp = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyStreams),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
            )
            
            var streamsDataSize: UInt32 = 0
            CMIOObjectGetPropertyDataSize(device, &streamsProp, 0, nil, &streamsDataSize)
            
            let streamCount = Int(streamsDataSize) / MemoryLayout<CMIOStreamID>.size
            var streams = Array(repeating: CMIOStreamID(0), count: streamCount)
            
            CMIOObjectGetPropertyData(device, &streamsProp, 0, nil, streamsDataSize, &streamsDataSize, &streams)
            
            print("  Found \(streamCount) streams:")
            
            for stream in streams where stream != 0 {
                // Get stream direction
                var directionProp = CMIOObjectPropertyAddress(
                    mSelector: CMIOObjectPropertySelector(kCMIOStreamPropertyDirection),
                    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
                )
                
                var direction: UInt32 = 0
                var directionSize = UInt32(MemoryLayout<UInt32>.size)
                
                if CMIOObjectGetPropertyData(stream, &directionProp, 0, nil, directionSize, &directionSize, &direction) == noErr {
                    let directionStr = direction == 0 ? "Output (Source)" : "Input (Sink)"
                    print("    Stream ID: \(stream) - Direction: \(directionStr)")
                }
            }
        }
    }
}
EOF

swift /tmp/enumerate_cmio_streams.swift

echo
echo "3. Monitoring logs for sink stream activity..."
echo "Press Ctrl+C to stop monitoring"
echo

# Monitor logs for 10 seconds
timeout 10 log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --style compact | grep -E "(sink|Sink|consume|startStream)"