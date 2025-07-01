#!/usr/bin/swift

import AVFoundation
import CoreMediaIO

// Allow virtual cameras
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

print("=== Checking for Virtual Cameras ===\n")

// List all video devices
let devices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.external, .builtInWideAngleCamera],
    mediaType: .video,
    position: .unspecified
).devices

print("Found \(devices.count) camera device(s):\n")

for device in devices {
    print("📷 \(device.localizedName)")
    print("   Model ID: \(device.modelID)")
    print("   Unique ID: \(device.uniqueID)")
    print("   Manufacturer: \(device.manufacturer)")
    print("")
}

// Look specifically for our virtual camera
let gigeCameras = devices.filter { $0.localizedName.contains("GigE") }
if gigeCameras.isEmpty {
    print("❌ GigE Virtual Camera not found")
    print("\nTroubleshooting:")
    print("1. Make sure the app is running")
    print("2. Check System Settings > Privacy & Security for extension approval")
    print("3. Try restarting the app after approval")
} else {
    print("✅ GigE Virtual Camera found!")
}