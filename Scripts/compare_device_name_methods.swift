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

// Test the exact method used by CMIOFrameSender
func getDeviceNameLikeCMIOFrameSender(deviceID: CMIODeviceID) -> String? {
    var propertyAddress = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    
    var dataSize: UInt32 = 0
    var dataUsed: UInt32 = 0
    
    let result = CMIOObjectGetPropertyDataSize(
        deviceID,
        &propertyAddress,
        0,
        nil,
        &dataSize
    )
    
    guard result == kCMIOHardwareNoError else { 
        print("Failed to get name size for device \(deviceID): \(result)")
        return nil 
    }
    
    var name: CFString = "" as CFString
    let nameResult = CMIOObjectGetPropertyData(
        deviceID,
        &propertyAddress,
        0,
        nil,
        dataSize,
        &dataUsed,
        &name
    )
    
    guard nameResult == kCMIOHardwareNoError else { return nil }
    
    return name as String
}

// Get all devices
var propertyAddress = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
var dataUsed: UInt32 = 0

CMIOObjectGetPropertyDataSize(
    CMIOObjectID(kCMIOObjectSystemObject),
    &propertyAddress,
    0,
    nil,
    &dataSize
)

if dataSize > 0 {
    let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
    var devices = Array<CMIODeviceID>(repeating: 0, count: deviceCount)
    
    CMIOObjectGetPropertyData(
        CMIOObjectID(kCMIOObjectSystemObject),
        &propertyAddress,
        0,
        nil,
        dataSize,
        &dataUsed,
        &devices
    )
    
    print("=== Testing CMIOFrameSender's getDeviceName method ===")
    print("Found \(deviceCount) devices:")
    
    for (index, device) in devices.enumerated() {
        if let name = getDeviceNameLikeCMIOFrameSender(deviceID: device) {
            print("\nDevice \(index): '\(name)' (ID: \(device))")
            print("Contains 'GigE Virtual Camera': \(name.contains("GigE Virtual Camera"))")
            
            // Also check case sensitivity
            print("Lowercase contains 'gige virtual camera': \(name.lowercased().contains("gige virtual camera"))")
            
            // Check exact string
            print("Exact match 'GigE Virtual Camera': \(name == "GigE Virtual Camera")")
            
            // Show character codes to check for hidden characters
            if name.contains("GigE") {
                print("Character codes: \(name.unicodeScalars.map { $0.value })")
            }
        } else {
            print("\nDevice \(index): Could not get name (ID: \(device))")
        }
    }
}