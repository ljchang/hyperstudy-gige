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
        
        logger.info("Initializing CameraDeviceSource...")
        
        // Create shared frame queue
        var queue: CMSimpleQueue?
        let queueStatus = CMSimpleQueueCreate(allocator: kCFAllocatorDefault, capacity: 30, queueOut: &queue)
        if queueStatus == noErr, let queue = queue {
            sharedFrameQueue = queue
            logger.info("Created shared frame queue with capacity 30")
        } else {
            logger.error("Failed to create shared frame queue: \(queueStatus)")
        }
        
        // Use a persistent device ID
        let deviceID = UUID(uuidString: "A8B5D2F4-1234-5678-9ABC-DEF012345678") ?? UUID()
        logger.info("Creating device with ID: \(deviceID.uuidString)")
        
        device = CMIOExtensionDevice(localizedName: CameraConstants.Camera.name,
                                     deviceID: deviceID,
                                     legacyDeviceID: nil,
                                     source: self)
        
        // Create sink stream (receives frames from app)
        sinkStream = CameraStreamSource(localizedName: "GigE Camera Input", 
                                       direction: .sink,
                                       deviceID: deviceID,
                                       frameQueue: sharedFrameQueue)
        
        // Create source stream (provides frames to clients)
        sourceStream = CameraStreamSource(localizedName: "GigE Camera Stream", 
                                         direction: .source,
                                         deviceID: deviceID,
                                         frameQueue: sharedFrameQueue)
        
        logger.info("Created sink and source streams with shared queue")
        
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
            .deviceModel,
            .deviceIsSuspended,
            .deviceLinkedCoreAudioDeviceUID
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
        
        if properties.contains(.deviceIsSuspended) {
            let suspended = CMIOExtensionPropertyState(value: NSNumber(value: false) as AnyObject)
            propertyStates[.deviceIsSuspended] = suspended
        }
        
        if properties.contains(.deviceLinkedCoreAudioDeviceUID) {
            // No audio device linked
            let noAudio = CMIOExtensionPropertyState(value: NSNull() as AnyObject)
            propertyStates[.deviceLinkedCoreAudioDeviceUID] = noAudio
        }
        
        return CMIOExtensionDeviceProperties(dictionary: propertyStates)
    }
    
    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
        // Device properties are read-only for our implementation
        // If we need to handle any property changes in the future, we can do so here
    }
}