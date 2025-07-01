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
            mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        let result = CMIOObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard result == kCMIOHardwareNoError else { return nil }
        
        var name: CFString = "" as CFString
        let nameResult = CMIOObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataUsed,
            &name
        )
        
        guard nameResult == kCMIOHardwareNoError else { return nil }
        
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
        
        // Find the sink stream by checking direction
        for streamID in streams {
            var directionAddress = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIOStreamPropertyDirection),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
            )
            
            var direction: UInt32 = 0
            let directionSize = UInt32(MemoryLayout<UInt32>.size)
            var directionUsed: UInt32 = 0
            
            let dirResult = CMIOObjectGetPropertyData(
                streamID,
                &directionAddress,
                0,
                nil,
                directionSize,
                &directionUsed,
                &direction
            )
            
            if dirResult == kCMIOHardwareNoError {
                logger.info("Stream \(streamID) direction: \(direction)")
                // Direction 1 = sink (input to device), 0 = source (output from device)
                if direction == 1 {
                    logger.info("Found sink stream: \(streamID)")
                    return streamID
                }
            }
        }
        
        logger.error("No sink stream found on device")
        return nil
    }
    
    private func startStreamAndGetQueue() -> Bool {
        guard let deviceID = deviceID, let streamID = sinkStreamID else {
            return false
        }
        
        // Get the stream's queue using CMIOStreamCopyBufferQueue
        var queue: Unmanaged<CMSimpleQueue>?
        let queueResult = CMIOStreamCopyBufferQueue(
            streamID,
            { (streamID, token, refCon) in
                // This callback is invoked when the queue state changes
                // We don't need to handle it for simple enqueuing
            },
            nil,
            &queue
        )
        
        guard queueResult == kCMIOHardwareNoError else {
            logger.error("Failed to get stream queue: \(queueResult)")
            return false
        }
        
        guard let q = queue else {
            logger.error("Stream queue is nil")
            return false
        }
        
        streamQueue = q
        logger.info("Successfully obtained stream queue")
        
        // Start the stream
        let result = CMIODeviceStartStream(deviceID, streamID)
        guard result == kCMIOHardwareNoError else {
            logger.error("Failed to start stream: \(result)")
            streamQueue = nil
            return false
        }
        
        logger.info("Stream started successfully")
        return true
    }
}