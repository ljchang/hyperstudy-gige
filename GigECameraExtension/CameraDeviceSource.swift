//
//  CameraDeviceSource.swift
//  GigECameraExtension
//
//  Created on 6/24/25.
//

import Foundation
import CoreMediaIO
import os.log

class CameraDeviceSource: NSObject, CMIOExtensionDeviceSource {
    
    // MARK: - Properties
    private(set) var device: CMIOExtensionDevice!
    private var streamSource: CameraStreamSource?
    private let logger = Logger(subsystem: CameraConstants.BundleID.cameraExtension, category: "Device")
    
    // MARK: - Initialization
    override init() {
        super.init()
        
        let deviceID = UUID()
        device = CMIOExtensionDevice(localizedName: CameraConstants.Camera.name,
                                     deviceID: deviceID,
                                     legacyDeviceID: nil,
                                     source: self)
        
        // Create stream
        streamSource = CameraStreamSource(localizedName: "GigE Camera Stream")
        
        do {
            try device.addStream(streamSource!.stream)
            logger.info("Stream added to device")
        } catch {
            logger.error("Failed to add stream: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CMIOExtensionDeviceSource
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [
            .deviceTransportType,
            .deviceModel
        ]
    }
    
    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        var propertyStates = [CMIOExtensionProperty: CMIOExtensionPropertyState<AnyObject>]()
        
        if properties.contains(.deviceTransportType) {
            let transportType = CMIOExtensionPropertyState(value: NSNumber(value: UInt32(0x76697274)) as AnyObject) // 'virt' in ASCII
            propertyStates[.deviceTransportType] = transportType
        }
        
        if properties.contains(.deviceModel) {
            let model = CMIOExtensionPropertyState(value: "GigE Vision Camera" as NSString as AnyObject)
            propertyStates[.deviceModel] = model
        }
        
        return CMIOExtensionDeviceProperties(dictionary: propertyStates)
    }
    
    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
        // Device properties are read-only for our implementation
        // If we need to handle any property changes in the future, we can do so here
    }
}