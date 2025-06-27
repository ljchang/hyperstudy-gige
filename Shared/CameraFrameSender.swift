//
//  CameraFrameSender.swift
//  GigEVirtualCamera
//
//  Handles sending frames from the main app to the camera extension
//

import Foundation
import CoreMediaIO
import CoreVideo
import os.log

class CameraFrameSender: NSObject {
    static let shared = CameraFrameSender()
    
    private let logger = Logger(subsystem: CameraConstants.BundleID.app, category: "FrameSender")
    private var streamSink: CMIOHardwareStreamSendSampleBuffer?
    private let gigEManager = GigECameraManager.shared
    private var isActive = false
    
    override init() {
        super.init()
        setupFrameHandler()
    }
    
    // MARK: - Setup
    
    private func setupFrameHandler() {
        // Register to receive frames from GigE camera
        gigEManager.addFrameHandler { [weak self] pixelBuffer in
            self?.sendFrameToExtension(pixelBuffer)
        }
    }
    
    // MARK: - Connection Management
    
    func connectToExtension() {
        logger.info("Attempting to connect to camera extension sink stream...")
        
        // Find our camera extension device
        guard let device = findCameraExtensionDevice() else {
            logger.error("Failed to find camera extension device")
            return
        }
        
        // Find the sink stream
        guard let sinkStream = findSinkStream(on: device) else {
            logger.error("Failed to find sink stream on device")
            return
        }
        
        // Create the stream sink
        var streamSinkOut: CMIOHardwareStreamSendSampleBuffer?
        let status = CMIOHardwareStreamSendSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            stream: sinkStream,
            streamSinkOut: &streamSinkOut
        )
        
        guard status == noErr, let sink = streamSinkOut else {
            logger.error("Failed to create stream sink: \(status)")
            return
        }
        
        streamSink = sink
        isActive = true
        logger.info("Successfully connected to camera extension sink stream")
    }
    
    func disconnect() {
        streamSink = nil
        isActive = false
        logger.info("Disconnected from camera extension")
    }
    
    // MARK: - Device Discovery
    
    private func findCameraExtensionDevice() -> CMIOObjectID? {
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        // Get the size of device list
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var status = CMIOObjectGetPropertyDataSize(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else {
            logger.error("Failed to get device list size: \(status)")
            return nil
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
        var devices = Array(repeating: CMIOObjectID(), count: deviceCount)
        
        status = CMIOObjectGetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataUsed,
            &devices
        )
        
        guard status == noErr else {
            logger.error("Failed to get device list: \(status)")
            return nil
        }
        
        // Find our camera extension device
        for device in devices {
            if let name = getDeviceName(device), name.contains("GigE") {
                logger.info("Found GigE camera device: \(name)")
                return device
            }
        }
        
        return nil
    }
    
    private func getDeviceName(_ device: CMIOObjectID) -> String? {
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(
            device,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else { return nil }
        
        var name: CFString = "" as CFString
        status = CMIOObjectGetPropertyData(
            device,
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataUsed,
            &name
        )
        
        guard status == noErr else { return nil }
        
        return name as String
    }
    
    private func findSinkStream(on device: CMIOObjectID) -> CMIOStreamID? {
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyStreams),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeInput),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(
            device,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else { return nil }
        
        let streamCount = Int(dataSize) / MemoryLayout<CMIOStreamID>.size
        var streams = Array(repeating: CMIOStreamID(), count: streamCount)
        
        status = CMIOObjectGetPropertyData(
            device,
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataUsed,
            &streams
        )
        
        guard status == noErr else { return nil }
        
        // Return the first sink stream found
        return streams.first
    }
    
    // MARK: - Frame Sending
    
    private func sendFrameToExtension(_ pixelBuffer: CVPixelBuffer) {
        guard isActive, let sink = streamSink else { return }
        
        // Create sample buffer from pixel buffer
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        
        guard let format = formatDescription else { return }
        
        var timingInfo = CMSampleTimingInfo()
        timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
        timingInfo.duration = CMTime(value: 1, timescale: 30) // 30 fps
        
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: format,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        guard let buffer = sampleBuffer else { return }
        
        // Send to extension
        let status = CMIOHardwareStreamSendSampleBuffer(sink, buffer)
        if status != noErr {
            logger.error("Failed to send frame: \(status)")
        }
    }
}