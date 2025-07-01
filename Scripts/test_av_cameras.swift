#!/usr/bin/swift

import AVFoundation

print("Discovering cameras using AVFoundation...")

// List all available cameras
let devices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInWideAngleCamera, .external],
    mediaType: .video,
    position: .unspecified
).devices

print("\nFound \(devices.count) camera(s):")
for device in devices {
    print("\n- Name: \(device.localizedName)")
    print("  ID: \(device.uniqueID)")
    print("  Model: \(device.modelID)")
    print("  Manufacturer: \(device.manufacturer)")
}

if devices.isEmpty {
    print("\nNo cameras found. Virtual cameras may need to be activated first.")
}