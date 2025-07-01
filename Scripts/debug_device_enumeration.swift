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

// Get all devices
var propertyAddress = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
var dataUsed: UInt32 = 0

// Get required size
var result = CMIOObjectGetPropertyDataSize(
    CMIOObjectID(kCMIOObjectSystemObject),
    &propertyAddress,
    0,
    nil,
    &dataSize
)

print("=== CMIO Device Enumeration Debug ===")
print("Get device list size result: \(result)")
print("Data size: \(dataSize)")

if result == kCMIOHardwareNoError && dataSize > 0 {
    let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
    var devices = Array<CMIODeviceID>(repeating: 0, count: deviceCount)
    
    result = CMIOObjectGetPropertyData(
        CMIOObjectID(kCMIOObjectSystemObject),
        &propertyAddress,
        0,
        nil,
        dataSize,
        &dataUsed,
        &devices
    )
    
    print("\nGet device list result: \(result)")
    print("Found \(deviceCount) devices:")
    
    for (index, device) in devices.enumerated() {
        print("\n--- Device \(index + 1) ---")
        print("Device ID: \(device)")
        
        // Get device name using same method as CMIOFrameSender
        var nameAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var nameDataSize: UInt32 = 0
        let nameSizeResult = CMIOObjectGetPropertyDataSize(
            device,
            &nameAddress,
            0,
            nil,
            &nameDataSize
        )
        
        print("Get name size result: \(nameSizeResult), size: \(nameDataSize)")
        
        if nameSizeResult == kCMIOHardwareNoError && nameDataSize > 0 {
            var name: CFString = "" as CFString
            let nameResult = CMIOObjectGetPropertyData(
                device,
                &nameAddress,
                0,
                nil,
                nameDataSize,
                &dataUsed,
                &name
            )
            
            print("Get name result: \(nameResult)")
            if nameResult == kCMIOHardwareNoError {
                let deviceName = name as String
                print("Name: '\(deviceName)'")
                print("Contains 'GigE Virtual Camera': \(deviceName.contains("GigE Virtual Camera"))")
            }
        }
    }
}