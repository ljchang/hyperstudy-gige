//
//  main.swift
//  GigEVirtualCameraExtension
//
//  Created by Luke Chang on 6/30/25.
//

import Foundation
import CoreMediaIO
import os.log

private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "Main")

// Debug: Write immediately when extension starts
NSLog("🔴 GigEVirtualCamera Extension: main.swift starting...")
if let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera") {
    defaults.set("Extension main.swift started at \(Date())", forKey: "Debug_MainStarted")
    
    // Clear any stale IOSurface IDs
    defaults.removeObject(forKey: "IOSurfaceIDs")
    defaults.synchronize()
    NSLog("🔴 GigEVirtualCamera Extension: Cleared stale IOSurface IDs")
}

// Use the simplified provider without sink streams
NSLog("🔴 GigEVirtualCamera Extension: Creating provider...")
let providerSource = GigEVirtualCameraExtensionProviderSource()

// Debug: Write after provider created
if let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera") {
    defaults.set("Provider created at \(Date())", forKey: "Debug_ProviderCreated")
    defaults.synchronize()
    NSLog("🔴 GigEVirtualCamera Extension: Provider created and debug info written")
}

NSLog("🔴 GigEVirtualCamera Extension: Starting CMIO service...")
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
