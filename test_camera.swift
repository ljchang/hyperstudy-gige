#!/usr/bin/env swift

import Foundation

// Simple test to check if we can discover GigE cameras
print("Testing GigE Camera Discovery...")

// Check if Aravis can be loaded
let aravisPath = "/opt/homebrew/lib/libaravis-0.8.dylib"
if FileManager.default.fileExists(atPath: aravisPath) {
    print("✓ Aravis library found at: \(aravisPath)")
} else {
    print("✗ Aravis library not found at expected location")
}

// Try to run arv-tool to list cameras
let process = Process()
process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/arv-tool-0.8")
process.arguments = ["--list-devices"]

do {
    print("\nRunning arv-tool to list devices...")
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("✓ arv-tool executed successfully")
    } else {
        print("✗ arv-tool failed with status: \(process.terminationStatus)")
    }
} catch {
    print("✗ Failed to run arv-tool: \(error)")
}

print("\nTo test camera manually, run:")
print("  arv-camera-test-0.8")
print("\nTo see available cameras, run:")
print("  arv-tool-0.8 --list-devices")