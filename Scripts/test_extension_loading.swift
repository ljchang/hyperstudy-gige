#!/usr/bin/swift

import Foundation
import CoreMediaIO
import AVFoundation

print("=== Testing Extension Loading ===")

// 1. Enable virtual camera discovery
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

print("\n1. Virtual camera discovery enabled")

// 2. List all CMIO devices before
print("\n2. CMIO devices before:")
listCMIODevices()

// 3. Try to access cameras through AVFoundation to trigger extension
print("\n3. Triggering extension through AVFoundation...")
let discovery = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInWideAngleCamera, .external],
    mediaType: .video,
    position: .unspecified
)

print("Found \(discovery.devices.count) devices through AVFoundation")
for device in discovery.devices {
    print("  - \(device.localizedName)")
}

// 4. Wait a bit
print("\n4. Waiting 3 seconds for extension to load...")
Thread.sleep(forTimeInterval: 3)

// 5. Check CMIO devices again
print("\n5. CMIO devices after:")
listCMIODevices()

// 6. Check if extension process is running
print("\n6. Checking extension process...")
let task = Process()
task.launchPath = "/bin/ps"
task.arguments = ["aux"]
let pipe = Pipe()
task.standardOutput = pipe
task.launch()
task.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
if let output = String(data: data, encoding: .utf8) {
    let lines = output.components(separatedBy: "\n")
    let extensionLines = lines.filter { $0.contains("GigECameraExtension") && !$0.contains("grep") }
    if extensionLines.isEmpty {
        print("Extension process NOT running")
    } else {
        print("Extension process IS running:")
        for line in extensionLines {
            print(line)
        }
    }
}

func listCMIODevices() {
    var propertyAddress = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    
    var dataSize: UInt32 = 0
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
        
        var dataUsed: UInt32 = 0
        CMIOObjectGetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataUsed,
            &devices
        )
        
        print("Found \(deviceCount) CMIO devices")
        
        for device in devices {
            var nameAddress = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
            )
            
            var nameSize: UInt32 = 0
            CMIOObjectGetPropertyDataSize(device, &nameAddress, 0, nil, &nameSize)
            
            if nameSize > 0 {
                var name: CFString?
                CMIOObjectGetPropertyData(
                    device,
                    &nameAddress,
                    0,
                    nil,
                    nameSize,
                    &dataUsed,
                    &name
                )
                
                if let deviceName = name as String? {
                    print("  - \(deviceName)")
                }
            }
        }
    }
}