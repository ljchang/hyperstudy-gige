#!/usr/bin/swift

import Foundation
import CoreMediaIO
import AVFoundation

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

print("=== CMIO Devices ===")

// Get all CMIO devices
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

if result == kCMIOHardwareNoError {
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
    
    if result == kCMIOHardwareNoError {
        print("Found \(deviceCount) CMIO devices:")
        
        for (index, device) in devices.enumerated() {
            // Get device name
            var nameAddress = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
            )
            
            var nameSize: UInt32 = 0
            CMIOObjectGetPropertyDataSize(device, &nameAddress, 0, nil, &nameSize)
            
            if nameSize > 0 {
                var name: CFString?
                let result = CMIOObjectGetPropertyData(
                    device,
                    &nameAddress,
                    0,
                    nil,
                    nameSize,
                    &dataUsed,
                    &name
                )
                
                if result == kCMIOHardwareNoError, let deviceName = name as String? {
                    print("\n\(index + 1). Device ID: \(device)")
                    print("   UID: \(deviceName)")
                    
                    // Get localized name
                    var localizedNameAddress = CMIOObjectPropertyAddress(
                        mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
                        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
                    )
                    
                    var localizedNameSize: UInt32 = 0
                    CMIOObjectGetPropertyDataSize(device, &localizedNameAddress, 0, nil, &localizedNameSize)
                    
                    if localizedNameSize > 0 {
                        var localizedName: CFString?
                        let result = CMIOObjectGetPropertyData(
                            device,
                            &localizedNameAddress,
                            0,
                            nil,
                            localizedNameSize,
                            &dataUsed,
                            &localizedName
                        )
                        
                        if result == kCMIOHardwareNoError, let name = localizedName as String? {
                            print("   Name: \(name)")
                            if name.contains("GigE") {
                                print("   *** This is the GigE Virtual Camera! ***")
                            }
                        }
                    }
                }
            }
        }
    }
}

print("\n=== AVFoundation Devices ===")
let avDevices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInWideAngleCamera, .external],
    mediaType: .video,
    position: .unspecified
).devices

for device in avDevices {
    print("- \(device.localizedName) [\(device.uniqueID)]")
}