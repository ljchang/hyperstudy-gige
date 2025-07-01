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
    private var streamQueue: CMSimpleQueue?
    
    // State tracking
    private var isConnected = false
    private var frameCount: UInt64 = 0
    private var lastQueueCheckTime = Date()
    private var queueInvalidCount = 0
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        // Allow discovery of virtual cameras
        enableVirtualCameraDiscovery()
    }
    
    // MARK: - Public Methods
    
    func connect() -> Bool {
        logger.info("Attempting to connect to virtual camera...")
        
        // Give the system a moment to register the extension
        Thread.sleep(forTimeInterval: 0.5)
        
        // Find our virtual camera device
        guard let device = findVirtualCamera() else {
            print("[CMIOFrameSender] ❌ Virtual camera device not found")
            logger.error("Virtual camera device not found")
            logger.error("Make sure the extension is running and the virtual camera is registered")
            logger.info("========================================")
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
        
        // For sink streams, we don't stop the stream - the client controls that
        // We just release our references
        
        if streamQueue != nil {
            // Release the queue
            logger.info("Releasing stream queue")
        }
        
        streamQueue = nil
        deviceID = nil
        sinkStreamID = nil
        isConnected = false
        
        logger.info("Disconnected from virtual camera")
    }
    
    func sendFrame(_ pixelBuffer: CVPixelBuffer) {
        guard self.isConnected else {
            if frameCount % 30 == 0 {
                logger.warning("Cannot send frame: not connected")
            }
            return
        }
        
        // Check if we need to refresh the queue periodically
        // This helps when Photo Booth starts streaming after our initial connection
        if streamQueue == nil || (Date().timeIntervalSince(lastQueueCheckTime) > 2.0) {
            logger.info("Attempting to refresh stream queue...")
            if refreshStreamQueue() {
                logger.info("✅ Successfully refreshed stream queue!")
                queueInvalidCount = 0
                lastQueueCheckTime = Date()
            }
        }
        
        guard let queue = self.streamQueue else {
            return
        }
        
        // Verify IOSurface backing
        guard let ioSurface = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
            logger.error("⚠️ Pixel buffer does not have IOSurface backing! This will fail cross-process sharing.")
            return
        }
        
        let surfaceID = IOSurfaceGetID(ioSurface)
        
        // Log first frame and every 30th frame with details
        if frameCount == 0 || frameCount % 30 == 0 {
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
            logger.info("📤 Sending frame #\(self.frameCount) to sink stream: \(width)x\(height), format: \(format), IOSurface ID: \(surfaceID)")
        }
        
        // Create timing info - IMPORTANT: Create fresh timing for each frame
        var timingInfo = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
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
        
        // Enqueue using the proper CMIO API
        // The queue expects the element to be a retained CMSampleBuffer
        // We use passUnretained and let the queue retain it
        let samplePtr = Unmanaged.passUnretained(sample).toOpaque()
        let result = CMSimpleQueueEnqueue(queue, element: samplePtr)
        
        if result == noErr {
            frameCount += 1
            queueInvalidCount = 0  // Reset error count on success
            if frameCount == 1 {
                print("[CMIOFrameSender] ✅ Successfully enqueued first frame to sink stream!")
                logger.info("✅ Successfully enqueued first frame to sink stream!")
                logger.info("Queue status after enqueue: count=\(CMSimpleQueueGetCount(queue)), capacity=\(CMSimpleQueueGetCapacity(queue))")
            } else if frameCount % 30 == 0 {
                print("[CMIOFrameSender] 📤 Sent frame #\(self.frameCount) to sink stream")
                logger.info("📤 Sent frame #\(self.frameCount) to sink stream")
                logger.info("Queue status: count=\(CMSimpleQueueGetCount(queue))")
            }
        } else {
            queueInvalidCount += 1
            if queueInvalidCount == 1 || queueInvalidCount == 5 || queueInvalidCount % 30 == 0 {
                logger.error("Failed to enqueue frame: \(result) (error count: \(self.queueInvalidCount))")
            }
            
            // Try to refresh on -12773 error, but not too frequently
            if result == -12773 {
                let timeSinceLastCheck = Date().timeIntervalSince(lastQueueCheckTime)
                if queueInvalidCount == 1 || timeSinceLastCheck > 1.0 {
                    logger.error("Queue appears to be invalid, will try to refresh")
                    // Try to refresh the queue
                    logger.info("Attempting queue refresh...")
                    lastQueueCheckTime = Date()
                    if refreshStreamQueue() {
                        logger.info("✅ Queue refresh successful!")
                        queueInvalidCount = 0
                        // The next frame will use the refreshed queue
                    } else {
                        logger.error("❌ Queue refresh failed")
                        streamQueue = nil  // Force re-obtain on next frame
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func listAllDevices() {
        // Removed - too verbose for normal operation
    }
    
    private func enableVirtualCameraDiscovery() {
        logger.info("Enabling virtual camera discovery...")
        
        // Enable screen capture devices (this also enables virtual cameras)
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var allow: UInt32 = 1
        let result = CMIOObjectSetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &property,
            0,
            nil,
            UInt32(MemoryLayout<UInt32>.size),
            &allow
        )
        
        if result == kCMIOHardwareNoError {
            logger.info("Virtual camera discovery enabled successfully")
        } else {
            logger.warning("Failed to enable virtual camera discovery: \(result)")
        }
    }
    
    private func findVirtualCamera() -> CMIODeviceID? {
        logger.info("Starting device discovery...")
        
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
        
        guard dataSize > 0 else {
            logger.error("Device list size is 0 - no devices found")
            return nil
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
        logger.info("Found \(deviceCount) total devices in system")
        
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
            if let name = getDeviceName(deviceID: device) {
                if name == "GigE Virtual Camera" || name.contains("GigE") {
                    logger.info("Found virtual camera: \(name)")
                    return device
                }
            }
        }
        
        logger.error("GigE Virtual Camera not found among \(deviceCount) devices")
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
        
        guard result == kCMIOHardwareNoError else { 
            logger.error("Failed to get name size for device \(deviceID): \(result)")
            return nil 
        }
        
        guard dataSize > 0 else {
            logger.error("Name size is 0 for device \(deviceID)")
            return nil
        }
        
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
        
        guard nameResult == kCMIOHardwareNoError else { 
            logger.error("Failed to get name for device \(deviceID): \(nameResult)")
            return nil 
        }
        
        let nameString = name as String
        logger.debug("Got device name: '\(nameString)' for device \(deviceID)")
        return nameString
    }
    
    private func findSinkStream(deviceID: CMIODeviceID) -> CMIOStreamID? {
        logger.info("Looking for sink stream on device \(deviceID)")
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
        logger.info("Checking \(streamCount) streams for sink stream...")
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
        guard let _ = deviceID, let streamID = sinkStreamID else {
            logger.error("Cannot get stream queue: deviceID=\(String(describing: self.deviceID)), streamID=\(String(describing: self.sinkStreamID))")
            return false
        }
        
        logger.info("Getting buffer queue for sink stream \(streamID)...")
        logger.info("NOTE: For sink streams, we don't start the stream - the client (Photo Booth) does that")
        
        // Get the stream's queue using CMIOStreamCopyBufferQueue
        var queue: Unmanaged<CMSimpleQueue>?
        let queueResult = CMIOStreamCopyBufferQueue(
            streamID,
            { (streamID, token, refCon) in
                // This callback is invoked when the queue state changes
                // Note: Can't capture self in C callback, so just log
                print("[CMIOFrameSender] Queue state changed for stream \(streamID)")
            },
            nil,
            &queue
        )
        
        guard queueResult == kCMIOHardwareNoError else {
            logger.error("Failed to get stream queue: \(queueResult) (kCMIOHardwareNoError=\(kCMIOHardwareNoError))")
            logger.error("This usually means the stream doesn't have a queue or isn't a sink stream")
            logger.error("Make sure Photo Booth or another client has the camera selected")
            return false
        }
        
        guard let unmanagedQueue = queue else {
            logger.error("Stream queue is nil after successful result")
            return false
        }
        
        // Take a retained reference since CMSimpleQueue uses reference counting
        streamQueue = unmanagedQueue.takeRetainedValue()
        logger.info("✅ Successfully obtained stream queue")
        
        // For sink streams, we don't start the stream ourselves
        // The client (Photo Booth) starts it when they begin capturing
        logger.info("✅ Ready to send frames to sink stream (waiting for client to start stream)")
        return true
    }
    
    private func refreshStreamQueue() -> Bool {
        guard let streamID = sinkStreamID else {
            logger.error("No sink stream ID available")
            return false
        }
        
        // Release old queue if any
        streamQueue = nil
        
        // Try to get the queue again
        var queue: Unmanaged<CMSimpleQueue>?
        let queueResult = CMIOStreamCopyBufferQueue(
            streamID,
            { (streamID, token, refCon) in
                print("[CMIOFrameSender] Queue state changed for stream \(streamID)")
            },
            nil,
            &queue
        )
        
        guard queueResult == kCMIOHardwareNoError else {
            logger.error("Failed to refresh stream queue: \(queueResult)")
            if queueResult == -12782 { // kCMIOHardwareIllegalOperationError
                logger.error("Stream may not be running - ensure Photo Booth has started streaming")
            } else if queueResult == -12783 { // kCMIOHardwareBadStreamError
                logger.error("Bad stream - stream ID may be invalid")
            }
            return false
        }
        
        guard let unmanagedQueue = queue else {
            logger.error("Queue is nil even though result was success")
            return false
        }
        
        streamQueue = unmanagedQueue.takeRetainedValue()
        logger.info("Successfully refreshed stream queue")
        return true
    }
}