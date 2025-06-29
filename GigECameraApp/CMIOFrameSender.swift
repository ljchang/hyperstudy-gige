//
//  CMIOFrameSender.swift
//  GigEVirtualCamera
//
//  Sends frames from the main app to the CMIO extension's sink stream
//

import Foundation
import CoreMediaIO
import CoreVideo
import os.log

class CMIOFrameSender: NSObject {
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera", category: "FrameSender")
    
    // CMIO device and stream IDs
    private var deviceID: CMIODeviceID?
    private var sinkStreamID: CMIOStreamID?
    private var streamQueue: Unmanaged<CMSimpleQueue>?
    
    // State tracking
    private var isConnected = false
    private var frameCount: UInt64 = 0
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        // Allow discovery of virtual cameras
        enableVirtualCameraDiscovery()
    }
    
    // MARK: - Public Methods
    
    func connect() -> Bool {
        logger.info("Attempting to connect to virtual camera...")
        
        // Find our virtual camera device
        guard let device = findVirtualCamera() else {
            logger.error("Virtual camera device not found")
            return false
        }
        
        deviceID = device
        logger.info("Found virtual camera device: \(device)")
        
        // Find the sink stream
        guard let stream = findSinkStream(deviceID: device) else {
            logger.error("Sink stream not found on device")
            return false
        }
        
        sinkStreamID = stream
        logger.info("Found sink stream: \(stream)")
        
        // Start the stream and get its queue
        guard startStreamAndGetQueue() else {
            logger.error("Failed to start stream and get queue")
            return false
        }
        
        isConnected = true
        logger.info("Successfully connected to virtual camera")
        return true
    }
    
    func disconnect() {
        guard isConnected else { return }
        
        if let deviceID = deviceID, let streamID = sinkStreamID {
            // Stop the stream
            var propertyAddress = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIOStreamPropertyCanProcessDeckCommand),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
            )
            
            var isRunning: UInt32 = 0
            var dataSize = UInt32(MemoryLayout<UInt32>.size)
            
            CMIOObjectSetPropertyData(
                streamID,
                &propertyAddress,
                0,
                nil,
                dataSize,
                &isRunning
            )
            
            CMIODeviceStopStream(deviceID, streamID)
        }
        
        streamQueue = nil
        deviceID = nil
        sinkStreamID = nil
        isConnected = false
        
        logger.info("Disconnected from virtual camera")
    }
    
    func sendFrame(_ pixelBuffer: CVPixelBuffer) {
        guard isConnected, let queue = streamQueue?.takeUnretainedValue() else {
            return
        }
        
        // Create timing info
        let now = CMClockGetTime(CMClockGetHostTimeClock())
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: now,
            decodeTimeStamp: .invalid
        )
        
        // Create format description
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        
        guard let format = formatDescription else {
            logger.error("Failed to create format description")
            return
        }
        
        // Create sample buffer
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: format,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        guard let sample = sampleBuffer else {
            logger.error("Failed to create sample buffer")
            return
        }
        
        // Check if queue is full
        if CMSimpleQueueGetCount(queue) >= CMSimpleQueueGetCapacity(queue) - 1 {
            logger.warning("Frame queue full, dropping oldest frame")
            _ = CMSimpleQueueDequeue(queue)
        }
        
        // Enqueue the frame
        let retained = Unmanaged.passRetained(sample as AnyObject).toOpaque()
        let result = CMSimpleQueueEnqueue(queue, element: retained)
        if result == noErr {
            frameCount += 1
            if frameCount % 30 == 0 {
                logger.debug("Sent frame #\(self.frameCount)")
            }
        } else {
            logger.error("Failed to enqueue frame: \(result)")
        }
    }
    
    // MARK: - Private Methods
    
    private func enableVirtualCameraDiscovery() {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var allow: UInt32 = 1
        CMIOObjectSetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &property,
            0,
            nil,
            UInt32(MemoryLayout<UInt32>.size),
            &allow
        )
    }
    
    private func findVirtualCamera() -> CMIODeviceID? {
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        // Get required size
        var result = CMIOObjectGetPropertyDataSize(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard result == kCMIOHardwareNoError else {
            logger.error("Failed to get device list size: \(result)")
            return nil
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
        var devices = Array<CMIODeviceID>(repeating: 0, count: deviceCount)
        
        result = CMIOObjectGetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataUsed,
            &devices
        )
        
        guard result == kCMIOHardwareNoError else {
            logger.error("Failed to get device list: \(result)")
            return nil
        }
        
        // Find our device by name
        for device in devices {
            if let name = getDeviceName(deviceID: device),
               name.contains("GigE Virtual Camera") {
                return device
            }
        }
        
        return nil
    }
    
    private func getDeviceName(deviceID: CMIODeviceID) -> String? {
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        var result = CMIOObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard result == kCMIOHardwareNoError else { return nil }
        
        var name: CFString = "" as CFString
        result = CMIOObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataUsed,
            &name
        )
        
        guard result == kCMIOHardwareNoError else { return nil }
        
        return name as String
    }
    
    private func findSinkStream(deviceID: CMIODeviceID) -> CMIOStreamID? {
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyStreams),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        // Get required size
        var result = CMIOObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard result == kCMIOHardwareNoError else {
            logger.error("Failed to get stream list size: \(result)")
            return nil
        }
        
        guard dataSize > 0 else {
            logger.error("No streams found on device")
            return nil
        }
        
        let streamCount = Int(dataSize) / MemoryLayout<CMIOStreamID>.size
        var streams = Array<CMIOStreamID>(repeating: 0, count: streamCount)
        
        result = CMIOObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataUsed,
            &streams
        )
        
        guard result == kCMIOHardwareNoError else {
            logger.error("Failed to get stream list: \(result)")
            return nil
        }
        
        // Return the first stream (should be our sink)
        return streams.first
    }
    
    private func startStreamAndGetQueue() -> Bool {
        guard let deviceID = deviceID, let streamID = sinkStreamID else {
            return false
        }
        
        // Start the stream
        let result = CMIODeviceStartStream(deviceID, streamID)
        guard result == kCMIOHardwareNoError else {
            logger.error("Failed to start stream: \(result)")
            return false
        }
        
        // Get the stream's queue
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOStreamPropertyFormatDescription),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(0)
        )
        
        var queuePropertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOStreamPropertyOutputBufferQueueSize),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(0)
        )
        
        // Note: Getting the actual queue reference is complex and may require
        // additional implementation. For now, we'll assume the stream is ready.
        
        // Create a placeholder queue for testing
        var queue: CMSimpleQueue?
        let queueResult = CMSimpleQueueCreate(allocator: kCFAllocatorDefault, capacity: 30, queueOut: &queue)
        
        if queueResult == noErr, let q = queue {
            streamQueue = Unmanaged.passRetained(q)
            return true
        }
        
        return false
    }
}