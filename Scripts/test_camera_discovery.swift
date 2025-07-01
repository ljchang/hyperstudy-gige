#!/usr/bin/swift

import AVFoundation
import CoreMediaIO

// Allow virtual cameras
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScopeGlobal,
    mElement: CMIOObjectPropertyElementMain
)
var allow: UInt32 = 1
CMIOObjectSetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &prop, 0, nil,
    UInt32(MemoryLayout<UInt32>.size),
    &allow
)

print("Discovering cameras...")

// List all available cameras
let devices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
    mediaType: .video,
    position: .unspecified
).devices

print("\nFound \(devices.count) camera(s):")
for device in devices {
    print("- \(device.localizedName) [\(device.uniqueID)]")
    print("  Model: \(device.modelID)")
    print("  Manufacturer: \(device.manufacturer)")
}

// Check for CMIO devices directly
print("\n\nChecking CMIO devices...")
var propertyAddress = CMIOObjectPropertyAddress(
    mSelector: kCMIOHardwarePropertyDevices,
    mScope: kCMIOObjectPropertyScopeGlobal,
    mElement: kCMIOObjectPropertyElementMain
)

var dataSize: UInt32 = 0
let sizeResult = CMIOObjectGetPropertyDataSize(
    CMIOObjectID(kCMIOObjectSystemObject),
    &propertyAddress,
    0,
    nil,
    &dataSize
)

if sizeResult == kCMIOHardwareNoError {
    let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
    var deviceIDs = Array(repeating: CMIODeviceID(0), count: deviceCount)
    var dataUsed: UInt32 = 0
    
    let result = CMIOObjectGetPropertyData(
        CMIOObjectID(kCMIOObjectSystemObject),
        &propertyAddress,
        0,
        nil,
        dataSize,
        &dataUsed,
        &deviceIDs
    )
    
    if result == kCMIOHardwareNoError {
        print("Found \(deviceCount) CMIO device(s):")
        
        for deviceID in deviceIDs {
            // Get device name
            var nameAddress = CMIOObjectPropertyAddress(
                mSelector: kCMIOObjectPropertyName,
                mScope: kCMIOObjectPropertyScopeGlobal,
                mElement: kCMIOObjectPropertyElementMain
            )
            
            var nameSize: UInt32 = 0
            CMIOObjectGetPropertyDataSize(deviceID, &nameAddress, 0, nil, &nameSize)
            
            if nameSize > 0 {
                var name: CFString?
                var nameUsed: UInt32 = 0
                CMIOObjectGetPropertyData(
                    deviceID,
                    &nameAddress,
                    0,
                    nil,
                    nameSize,
                    &nameUsed,
                    &name
                )
                
                if let deviceName = name as String? {
                    print("- CMIO Device: \(deviceName) [ID: \(deviceID)]")
                }
            }
        }
    }
} else {
    print("Error getting CMIO devices: \(sizeResult)")
}