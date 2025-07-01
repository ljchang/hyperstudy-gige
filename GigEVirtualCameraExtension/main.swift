//
//  main.swift
//  GigEVirtualCameraExtension
//
//  Created by Luke Chang on 6/30/25.
//

import Foundation
import CoreMediaIO

let providerSource = GigEVirtualCameraExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
