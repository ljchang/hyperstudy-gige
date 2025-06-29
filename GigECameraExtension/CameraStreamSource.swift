//
//  CameraStreamSource.swift
//  GigECameraExtension
//
//  Created on 6/24/25.
//

import Foundation
import CoreMediaIO
import CoreVideo
import os.log

class CameraStreamSource: NSObject, CMIOExtensionStreamSource {
    
    // MARK: - Properties
    private(set) var stream: CMIOExtensionStream!
    private let logger = Logger(subsystem: CameraConstants.BundleID.cameraExtension, category: "Stream")
    
    // Streaming state
    private var isStreaming = false
    private var timer: DispatchSourceTimer?
    private let streamQueue = DispatchQueue(label: "com.lukechang.gigecamera.stream", qos: .userInitiated)
    
    // Format management
    private var _activeFormatIndex = 0
    private let _formats: [CMIOExtensionStreamFormat]
    
    // Frame generation
    private var frameCounter: UInt64 = 0
    
    // Frame queue for sink/source pattern
    private var frameQueue: CMSimpleQueue?
    private let queueLock = NSLock()
    
    // Test pattern mode (used when no frames from sink)
    private var useTestPattern = true
    
    // MARK: - Initialization
    init(localizedName: String, direction: CMIOExtensionStream.Direction = .source) {
        // Create supported formats
        var formatList: [CMIOExtensionStreamFormat] = []
        
        for format in CameraConstants.Formats.all {
            if let videoFormat = Self.createFormat(width: format.width,
                                                  height: format.height,
                                                  frameRate: format.frameRate) {
                formatList.append(videoFormat)
            }
        }
        
        self._formats = formatList
        
        super.init()
        
        // Create stream
        let streamID = UUID()
        stream = CMIOExtensionStream(localizedName: localizedName,
                                     streamID: streamID,
                                     direction: direction,
                                     clockType: .hostTime,
                                     source: self)
        
        logger.info("Created \(direction == .source ? "source" : "sink") stream: \(localizedName)")
    }
    
    // MARK: - Format Creation
    private static func createFormat(width: Int, height: Int, frameRate: Int) -> CMIOExtensionStreamFormat? {
        let pixelFormat = kCVPixelFormatType_422YpCbCr8
        
        var formatDescription: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: pixelFormat,
            width: Int32(width),
            height: Int32(height),
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let format = formatDescription else {
            return nil
        }
        
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
        
        return CMIOExtensionStreamFormat(
            formatDescription: format,
            maxFrameDuration: frameDuration,
            minFrameDuration: frameDuration,
            validFrameDurations: nil
        )
    }
    
    // MARK: - CMIOExtensionStreamSource Protocol
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [
            .streamActiveFormatIndex,
            .streamFrameDuration,
            .streamMaxFrameDuration,
            .streamSinkBufferQueueSize,
            .streamSinkBuffersRequiredForStartup
        ]
    }
    
    var formats: [CMIOExtensionStreamFormat] {
        return _formats
    }
    
    var activeFormatIndex: Int {
        get { return _activeFormatIndex }
        set {
            guard newValue >= 0 && newValue < _formats.count else { return }
            
            logger.info("Switching to format index: \(newValue)")
            _activeFormatIndex = newValue
            
            // Restart streaming with new format if active
            if isStreaming {
                stopStreaming()
                startStreaming()
            }
        }
    }
    
    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = _activeFormatIndex
        }
        
        if properties.contains(.streamFrameDuration) {
            streamProperties.frameDuration = _formats[_activeFormatIndex].maxFrameDuration
        }
        
        if properties.contains(.streamSinkBufferQueueSize) {
            streamProperties.sinkBufferQueueSize = 30
        }
        
        if properties.contains(.streamSinkBuffersRequiredForStartup) {
            streamProperties.sinkBuffersRequiredForStartup = 1
        }
        
        return streamProperties
    }
    
    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        if let newFormatIndex = streamProperties.activeFormatIndex {
            activeFormatIndex = newFormatIndex
        }
    }
    
    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        // Always allow streaming
        return true
    }
    
    func startStream() throws {
        guard !isStreaming else { return }
        
        logger.info("Starting stream...")
        isStreaming = true
        
        startStreaming()
    }
    
    func stopStream() throws {
        guard isStreaming else { return }
        
        logger.info("Stopping stream...")
        isStreaming = false
        
        stopStreaming()
    }
    
    // MARK: - Sink Stream Support
    
    func consumeSampleBuffer(from client: CMIOExtensionClient, 
                           sample: CMSampleBuffer,
                           discontinuity: CMIOExtensionStream.DiscontinuityFlags,
                           hostTimeInNanoseconds: UInt64) {
        // This method is called when we receive frames as a sink
        guard stream.direction == .sink else { return }
        
        queueLock.lock()
        if let queue = frameQueue {
            // Check if queue is full
            if CMSimpleQueueGetCount(queue) < CMSimpleQueueGetCapacity(queue) {
                let retained = Unmanaged.passRetained(sample as AnyObject).toOpaque()
                CMSimpleQueueEnqueue(queue, element: retained)
                useTestPattern = false
            } else {
                logger.warning("Frame queue full, dropping frame")
            }
        }
        queueLock.unlock()
    }
    
    // MARK: - Source Stream Support
    
    func getFrameFromQueue() -> CMSampleBuffer? {
        guard stream.direction == .source else { return nil }
        
        queueLock.lock()
        defer { queueLock.unlock() }
        
        if let queue = frameQueue,
           CMSimpleQueueGetCount(queue) > 0,
           let framePtr = CMSimpleQueueDequeue(queue) {
            let frame = Unmanaged<AnyObject>.fromOpaque(framePtr).takeRetainedValue()
            return (frame as! CMSampleBuffer)
        }
        
        return nil
    }
    
    // MARK: - Streaming Control
    
    func startStreaming() {
        guard isStreaming else { return }
        
        // Only start timer for source streams
        guard stream.direction == .source else { return }
        
        // Get current format
        let format = _formats[_activeFormatIndex]
        let formatDesc = format.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDesc)
        let frameDuration = format.maxFrameDuration
        let frameRate = 1.0 / CMTimeGetSeconds(frameDuration)
        
        logger.info("Starting source stream: \(dimensions.width)x\(dimensions.height) @ \(frameRate)fps")
        
        // Create timer for frame generation
        timer = DispatchSource.makeTimerSource(queue: streamQueue)
        timer?.schedule(deadline: .now(), repeating: frameDuration.seconds)
        timer?.setEventHandler { [weak self] in
            self?.generateAndSendFrame()
        }
        timer?.resume()
    }
    
    func stopStreaming() {
        timer?.cancel()
        timer = nil
    }
    
    // MARK: - Frame Generation
    
    private func generateAndSendFrame() {
        autoreleasepool {
            // Try to get frame from queue first
            if let queuedFrame = getFrameFromQueue() {
                // Send the queued frame
                if CMSampleBufferGetImageBuffer(queuedFrame) != nil {
                    let timestamp = CMSampleBufferGetPresentationTimeStamp(queuedFrame)
                    stream.send(queuedFrame, discontinuity: [], 
                              hostTimeInNanoseconds: UInt64(timestamp.seconds * 1_000_000_000))
                }
                return
            }
            
            // If no frames in queue and test pattern is enabled, generate one
            if useTestPattern {
                generateTestPatternFrame()
            }
        }
    }
    
    private func generateTestPatternFrame() {
        guard let format = _formats[safe: _activeFormatIndex] else { return }
        
        let formatDesc = format.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDesc)
        
        // Create pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(dimensions.width),
            Int(dimensions.height),
            kCVPixelFormatType_422YpCbCr8,
            [
                kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
            ] as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            logger.error("Failed to create pixel buffer")
            return
        }
        
        // Fill with test pattern
        fillTestPattern(pixelBuffer: buffer, frameNumber: frameCounter)
        frameCounter += 1
        
        // Create timing info
        var timingInfo = CMSampleTimingInfo()
        timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
        timingInfo.duration = format.maxFrameDuration
        
        // Create sample buffer
        var sampleBuffer: CMSampleBuffer?
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                    imageBuffer: buffer,
                                                    formatDescriptionOut: &formatDescription)
        
        if let formatDesc = formatDescription {
            var sampleTiming = timingInfo
            
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: buffer,
                formatDescription: formatDesc,
                sampleTiming: &sampleTiming,
                sampleBufferOut: &sampleBuffer
            )
            
            if let sampleBuffer = sampleBuffer {
                // Send frame
                stream.send(sampleBuffer, discontinuity: [], 
                          hostTimeInNanoseconds: UInt64(timingInfo.presentationTimeStamp.seconds * 1_000_000_000))
            }
        }
    }
    
    private func fillTestPattern(pixelBuffer: CVPixelBuffer, frameNumber: UInt64) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        
        let buffer = baseAddress.bindMemory(to: UInt8.self, capacity: bytesPerRow * height)
        
        // Generate color bars pattern
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * 2
                
                // Simple color bars
                let barWidth = width / 8
                let barIndex = x / barWidth
                
                var cb: UInt8 = 128
                var y0: UInt8 = 128
                var cr: UInt8 = 128
                var y1: UInt8 = 128
                
                switch barIndex {
                case 0: // White
                    y0 = 235; y1 = 235; cb = 128; cr = 128
                case 1: // Yellow
                    y0 = 210; y1 = 210; cb = 16; cr = 146
                case 2: // Cyan
                    y0 = 170; y1 = 170; cb = 166; cr = 16
                case 3: // Green
                    y0 = 145; y1 = 145; cb = 54; cr = 34
                case 4: // Magenta
                    y0 = 106; y1 = 106; cb = 202; cr = 222
                case 5: // Red
                    y0 = 81; y1 = 81; cb = 90; cr = 240
                case 6: // Blue
                    y0 = 41; y1 = 41; cb = 240; cr = 110
                default: // Black
                    y0 = 16; y1 = 16; cb = 128; cr = 128
                }
                
                // Add some animation
                let animOffset = UInt8((frameNumber / 30) % 20)
                y0 = UInt8(clamping: Int(y0) + Int(animOffset))
                y1 = UInt8(clamping: Int(y1) + Int(animOffset))
                
                // YUV 422 format: Cb Y0 Cr Y1
                if x % 2 == 0 {
                    buffer[pixelIndex] = cb
                    buffer[pixelIndex + 1] = y0
                } else {
                    buffer[pixelIndex] = cr
                    buffer[pixelIndex + 1] = y1
                }
            }
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}