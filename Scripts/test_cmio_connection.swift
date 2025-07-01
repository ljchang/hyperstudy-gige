#!/usr/bin/swift

import Foundation
import CoreMediaIO

// Enable virtual camera discovery
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

print("Virtual camera discovery enabled")

// Get all devices
var devicesProp = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
var dataUsed: UInt32 = 0

CMIOObjectGetPropertyDataSize(
    CMIOObjectID(kCMIOObjectSystemObject),
    &devicesProp,
    0,
    nil,
    &dataSize
)

let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
var devices = Array<CMIODeviceID>(repeating: 0, count: deviceCount)

CMIOObjectGetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &devicesProp,
    0,
    nil,
    dataSize,
    &dataUsed,
    &devices
)

print("\nFound \(deviceCount) devices:")

// Check each device
for device in devices {
    // Get device name
    var nameProp = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    
    var nameSize: UInt32 = 0
    CMIOObjectGetPropertyDataSize(device, &nameProp, 0, nil, &nameSize)
    
    if nameSize > 0 {
        var name: CFString = "" as CFString
        CMIOObjectGetPropertyData(device, &nameProp, 0, nil, nameSize, &dataUsed, &name)
        
        print("\nDevice ID: \(device)")
        print("Name: \(name)")
        
        if (name as String).contains("GigE") {
            print("✅ Found GigE Virtual Camera!")
            
            // Get streams
            var streamsProp = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyStreams),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
            )
            
            var streamsSize: UInt32 = 0
            CMIOObjectGetPropertyDataSize(device, &streamsProp, 0, nil, &streamsSize)
            
            let streamCount = Int(streamsSize) / MemoryLayout<CMIOStreamID>.size
            var streams = Array<CMIOStreamID>(repeating: 0, count: streamCount)
            
            CMIOObjectGetPropertyData(device, &streamsProp, 0, nil, streamsSize, &dataUsed, &streams)
            
            print("Found \(streamCount) streams:")
            
            for streamID in streams {
                // Check stream direction
                var dirProp = CMIOObjectPropertyAddress(
                    mSelector: CMIOObjectPropertySelector(kCMIOStreamPropertyDirection),
                    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
                )
                
                var direction: UInt32 = 0
                let dirSize = UInt32(MemoryLayout<UInt32>.size)
                
                CMIOObjectGetPropertyData(streamID, &dirProp, 0, nil, dirSize, &dataUsed, &direction)
                
                print("  Stream ID: \(streamID), Direction: \(direction == 1 ? "Sink" : "Source")")
                
                if direction == 1 {
                    print("  ✅ Found sink stream! Attempting to get buffer queue...")
                    
                    // Try to get buffer queue
                    var queue: Unmanaged<CMSimpleQueue>?
                    let result = CMIOStreamCopyBufferQueue(
                        streamID,
                        { (streamID, token, refCon) in
                            print("Queue callback called")
                        },
                        nil,
                        &queue
                    )
                    
                    if result == kCMIOHardwareNoError, let q = queue {
                        print("  ✅ Successfully got buffer queue!")
                        _ = q.takeUnretainedValue()
                    } else {
                        print("  ❌ Failed to get buffer queue: \(result)")
                    }
                }
            }
        }
    }
}