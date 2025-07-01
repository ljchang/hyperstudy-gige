#!/usr/bin/env swift

import Foundation
import CoreMediaIO

print("=== CMIO Device Discovery Test ===")
print("")

// Enable virtual camera discovery
var property = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var allow: UInt32 = 1
let enableResult = CMIOObjectSetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &property,
    0,
    nil,
    UInt32(MemoryLayout<UInt32>.size),
    &allow
)

print("1. Virtual camera discovery enabled: \(enableResult == kCMIOHardwareNoError ? "YES" : "NO (error: \(enableResult))")")
print("")

// Get device list
var deviceProperty = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
var dataUsed: UInt32 = 0

let sizeResult = CMIOObjectGetPropertyDataSize(
    CMIOObjectID(kCMIOObjectSystemObject),
    &deviceProperty,
    0,
    nil,
    &dataSize
)

guard sizeResult == kCMIOHardwareNoError else {
    print("ERROR: Failed to get device list size: \(sizeResult)")
    exit(1)
}

let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
print("2. Found \(deviceCount) CMIO devices")
print("")

var devices = Array<CMIODeviceID>(repeating: 0, count: deviceCount)

let getResult = CMIOObjectGetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &deviceProperty,
    0,
    nil,
    dataSize,
    &dataUsed,
    &devices
)

guard getResult == kCMIOHardwareNoError else {
    print("ERROR: Failed to get device list: \(getResult)")
    exit(1)
}

// List all devices
print("3. Device Details:")
print("==================")

for (index, deviceID) in devices.enumerated() {
    print("\nDevice \(index):")
    print("  ID: \(deviceID)")
    
    // Get name
    var nameProperty = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    
    var nameDataSize: UInt32 = 0
    let nameSizeResult = CMIOObjectGetPropertyDataSize(
        deviceID,
        &nameProperty,
        0,
        nil,
        &nameDataSize
    )
    
    if nameSizeResult == kCMIOHardwareNoError && nameDataSize > 0 {
        var name: CFString = "" as CFString
        var nameDataUsed: UInt32 = 0
        let nameResult = CMIOObjectGetPropertyData(
            deviceID,
            &nameProperty,
            0,
            nil,
            nameDataSize,
            &nameDataUsed,
            &name
        )
        
        if nameResult == kCMIOHardwareNoError {
            print("  Name: '\(name)'")
            
            // Check if it's our virtual camera
            let nameString = name as String
            if nameString.contains("GigE") {
                print("  ✅ THIS IS THE GIGE VIRTUAL CAMERA!")
            }
        } else {
            print("  Name: <error getting name: \(nameResult)>")
        }
    } else {
        print("  Name: <no name available>")
    }
    
    // Get model
    var modelProperty = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyModelUID),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    
    var modelDataSize: UInt32 = 0
    let modelSizeResult = CMIOObjectGetPropertyDataSize(
        deviceID,
        &modelProperty,
        0,
        nil,
        &modelDataSize
    )
    
    if modelSizeResult == kCMIOHardwareNoError && modelDataSize > 0 {
        var model: CFString = "" as CFString
        var modelDataUsed: UInt32 = 0
        let modelResult = CMIOObjectGetPropertyData(
            deviceID,
            &modelProperty,
            0,
            nil,
            modelDataSize,
            &modelDataUsed,
            &model
        )
        
        if modelResult == kCMIOHardwareNoError {
            print("  Model: '\(model)'")
        }
    }
}

print("\n=== Test Complete ===")