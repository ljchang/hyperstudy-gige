//
//  CameraProviderSource.swift
//  GigECameraExtension
//
//  Created on 6/24/25.
//

import Foundation
import CoreMediaIO
import os.log

class CameraProviderSource: NSObject, CMIOExtensionProviderSource {
    
    // MARK: - Properties
    private(set) var provider: CMIOExtensionProvider!
    private var deviceSource: CameraDeviceSource?
    private let logger = Logger(subsystem: CameraConstants.BundleID.cameraExtension, category: "Provider")
    
    // MARK: - Initialization
    override init() {
        super.init()
        
        provider = CMIOExtensionProvider(source: self, clientQueue: .main)
    }
    
    // MARK: - CMIOExtensionProviderSource
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [
            .providerManufacturer,
            .providerName
        ]
    }
    
    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = CameraConstants.Camera.manufacturer
        }
        
        if properties.contains(.providerName) {
            providerProperties.name = CameraConstants.Camera.name
        }
        
        return providerProperties
    }
    
    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
        // Provider properties are read-only
    }
    
    func connect(to client: CMIOExtensionClient) throws {
        logger.info("Client connected: \(client.description)")
        
        // Initialize Aravis if needed (will be implemented later)
        // For now, create a test device
        
        if deviceSource == nil {
            deviceSource = CameraDeviceSource()
            
            do {
                try provider.addDevice(deviceSource!.device)
                logger.info("Device added successfully")
            } catch {
                logger.error("Failed to add device: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    func disconnect(from client: CMIOExtensionClient) {
        logger.info("Client disconnected: \(client.description)")
        
        // Keep the device active even when clients disconnect
        // This prevents the camera from disappearing and reappearing
    }
}