//
//  main.swift
//  GigECameraExtension
//
//  Created on 6/24/25.
//

import Foundation
import CoreMediaIO
import os.log

// This is the entry point for the camera extension
let logger = OSLog(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "Main")

os_log("========================================", log: logger, type: .info)
os_log("GigE Camera Extension starting...", log: logger, type: .info)
os_log("Bundle ID: %{public}@", log: logger, type: .info, Bundle.main.bundleIdentifier ?? "Unknown")
os_log("Process ID: %d", log: logger, type: .info, ProcessInfo.processInfo.processIdentifier)
os_log("========================================", log: logger, type: .info)

let providerSource = CameraProviderSource()
os_log("✅ Provider source created successfully", log: logger, type: .info)

os_log("Starting CMIO service...", log: logger, type: .info)
CMIOExtensionProvider.startService(provider: providerSource.provider)

os_log("✅ CMIO service started - extension should now be discoverable", log: logger, type: .info)