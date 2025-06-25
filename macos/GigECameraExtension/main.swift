//
//  main.swift
//  GigECameraExtension
//
//  Created on 6/24/25.
//

import Foundation
import CoreMediaIO
import os.log

let logger = Logger(subsystem: CameraConstants.BundleID.cameraExtension, category: "Main")

logger.info("Starting GigE Camera Extension...")

// Create and start the provider
let providerSource = CameraProviderSource()
CMIOExtensionProvider.startService(provider: providerSource.provider)

logger.info("GigE Camera Extension started successfully")