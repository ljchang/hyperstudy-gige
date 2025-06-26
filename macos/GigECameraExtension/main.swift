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

os_log("GigE Camera Extension starting...", log: logger, type: .info)

let providerSource = CameraProviderSource()

os_log("Provider source created, starting CMIO service...", log: logger, type: .info)

CMIOExtensionProvider.startService(provider: providerSource.provider)

os_log("CMIO service started", log: logger, type: .info)