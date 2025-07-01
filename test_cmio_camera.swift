#!/usr/bin/env swift

import AVFoundation
import CoreMediaIO

// Enable discovery of virtual cameras
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

print("=== Testing CMIO Camera Extension ===\n")

// List all available cameras
print("Available cameras:")
let devices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.external, .builtInWideAngleCamera],
    mediaType: .video,
    position: .unspecified
).devices

for (index, device) in devices.enumerated() {
    print("\(index + 1). \(device.localizedName)")
    print("   Model ID: \(device.modelID)")
    print("   Unique ID: \(device.uniqueID)")
    print("   Manufacturer: \(device.manufacturer)")
    
    // Check if it's our virtual camera
    if device.localizedName.contains("GigE Virtual Camera") {
        print("   >>> Found GigE Virtual Camera!")
        
        // Try to create a capture session
        print("\n   Testing capture session...")
        let session = AVCaptureSession()
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                print("   >>> Successfully added to capture session")
            } else {
                print("   XXX Cannot add to capture session")
            }
        } catch {
            print("   XXX Failed to create input: \(error)")
        }
    }
    print()
}

if !devices.contains(where: { $0.localizedName.contains("GigE Virtual Camera") }) {
    print("XXX GigE Virtual Camera not found!")
    print("\nTroubleshooting:")
    print("1. Make sure the app is installed in /Applications")
    print("2. Run the app and click 'Install Extension'")
    print("3. Grant permission in System Settings > Privacy & Security")
    print("4. Try running: systemextensionsctl list")
}

print("\n=== Test Complete ===")