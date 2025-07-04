#!/usr/bin/swift

import Foundation
import CoreMediaIO
import os.log

// Test if we can manually initialize the property listener

print("Testing CMIOPropertyListener initialization...")

// First check if we can see CMIO devices
var property = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
var result = CMIOObjectGetPropertyDataSize(
    CMIOObjectID(kCMIOObjectSystemObject),
    &property,
    0,
    nil,
    &dataSize
)

if result == kCMIOHardwareNoError {
    print("✅ Can access CMIO hardware properties")
    
    let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
    print("Found \(deviceCount) CMIO devices")
    
    // Try to set up a listener
    let listenerBlock: CMIOObjectPropertyListenerBlock = { _, _, _, _ in
        print("🎯 Property change detected!")
        return kCMIOHardwareNoError
    }
    
    result = CMIOObjectAddPropertyListenerBlock(
        CMIOObjectID(kCMIOObjectSystemObject),
        &property,
        nil,
        listenerBlock
    )
    
    if result == kCMIOHardwareNoError {
        print("✅ Successfully added property listener")
    } else {
        print("❌ Failed to add property listener: \(result)")
    }
} else {
    print("❌ Cannot access CMIO hardware: \(result)")
}

// Check if our virtual camera is visible
var deviceIDs = Array(repeating: CMIODeviceID(0), count: Int(dataSize) / MemoryLayout<CMIODeviceID>.size)
var dataUsed: UInt32 = 0

result = CMIOObjectGetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &property,
    0,
    nil,
    dataSize,
    &dataUsed,
    &deviceIDs
)

if result == kCMIOHardwareNoError {
    print("\nLooking for GigE Virtual Camera...")
    
    for deviceID in deviceIDs where deviceID != 0 {
        // Get device UID
        var uidProperty = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var uidSize: UInt32 = 0
        result = CMIOObjectGetPropertyDataSize(deviceID, &uidProperty, 0, nil, &uidSize)
        
        if result == kCMIOHardwareNoError {
            let uidPtr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
            defer { uidPtr.deallocate() }
            
            result = CMIOObjectGetPropertyData(deviceID, &uidProperty, 0, nil, uidSize, &dataUsed, uidPtr)
            
            if result == kCMIOHardwareNoError, let uid = uidPtr.pointee {
                let uidString = uid as String
                print("Device \(deviceID): \(uidString)")
                
                if uidString.contains("4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4") {
                    print("✅ Found GigE Virtual Camera!")
                }
            }
        }
    }
}

print("\nTest complete.")