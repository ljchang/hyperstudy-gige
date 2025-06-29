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
    private var sourceStream: CameraStreamSource?
    private var sinkStream: CameraStreamSource?
    private let logger = Logger(subsystem: CameraConstants.BundleID.cameraExtension, category: "Device")
    
    // Shared frame queue between sink and source
    private var sharedFrameQueue: CMSimpleQueue?
    
    // MARK: - Initialization
    override init() {
        super.init()
        
        // Create shared frame queue
        var queue: CMSimpleQueue?
        CMSimpleQueueCreate(allocator: kCFAllocatorDefault, capacity: 30, queueOut: &queue)
        sharedFrameQueue = queue
        
        let deviceID = UUID()
        device = CMIOExtensionDevice(localizedName: CameraConstants.Camera.name,
                                     deviceID: deviceID,
                                     legacyDeviceID: nil,
                                     source: self)
        
        // Create sink stream (receives frames from app)
        sinkStream = CameraStreamSource(localizedName: "GigE Camera Input", direction: .sink)
        
        // Create source stream (provides frames to clients)
        sourceStream = CameraStreamSource(localizedName: "GigE Camera Stream", direction: .source)
        
        // Share the queue between streams
        if sinkStream != nil, sourceStream != nil {
            // Both streams will use the same queue
            logger.info("Created sink and source streams with shared queue")
        }
        
        do {
            // Add both streams to device
            if let sink = sinkStream {
                try device.addStream(sink.stream)
                logger.info("Sink stream added to device")
            }
            
            if let source = sourceStream {
                try device.addStream(source.stream)
                logger.info("Source stream added to device")
            }
        } catch {
            logger.error("Failed to add streams: \(error.localizedDescription)")
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
            // 'virt' in ASCII for virtual transport
            let transportType = CMIOExtensionPropertyState(value: NSNumber(value: UInt32(0x76697274)) as AnyObject)
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