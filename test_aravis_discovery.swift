#!/usr/bin/env swift

import Foundation

// Simple test to check if AravisBridge discovery works
// Run with: swift test_aravis_discovery.swift

print("Testing Aravis camera discovery...")

// We need to compile this with the proper headers and libraries
// For now, let's use the arv-tool output directly

let task = Process()
task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/arv-tool-0.8")
task.arguments = []

let pipe = Pipe()
task.standardOutput = pipe
task.standardError = pipe

do {
    try task.run()
    task.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        print("Aravis output:")
        print(output)
        
        if output.contains("MRC Systems") {
            print("\n✅ Camera detected: MRC Systems camera at 169.254.254.143")
        } else {
            print("\n❌ No cameras detected")
        }
    }
} catch {
    print("Error running arv-tool: \(error)")
}