#!/usr/bin/swift

import AVFoundation
import CoreMediaIO

// Allow third-party camera extensions
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var allow: UInt32 = 1
let dataSize = UInt32(MemoryLayout<UInt32>.size)
var dataUsed: UInt32 = 0

CMIOObjectSetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &prop,
    0,
    nil,
    dataSize,
    &allow
)

print("Enabled third-party camera extensions")

// List all video devices
print("\nAvailable cameras:")
let devices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
    mediaType: .video,
    position: .unspecified
).devices

for device in devices {
    print("- \(device.localizedName) [\(device.uniqueID)]")
}

if devices.isEmpty {
    print("No cameras found")
}

print("\nIf GigE Virtual Camera is not listed:")
print("1. Go to System Settings > General > Login Items & Extensions")
print("2. Click on 'Camera Extensions'")
print("3. Enable 'GigE Camera Extension'")
print("4. Restart this test or your camera app")