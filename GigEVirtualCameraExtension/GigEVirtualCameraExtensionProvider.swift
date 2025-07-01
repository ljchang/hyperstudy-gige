//
//  GigEVirtualCameraExtensionProvider.swift
//  GigEVirtualCameraExtension
//
//  Created by Luke Chang on 6/30/25.
//

import Foundation
import CoreMediaIO
import IOKit.audio
import os.log

// MARK: - Device Source

class GigEVirtualCameraExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource {
    
    private(set) var device: CMIOExtensionDevice!
    private var _sourceStreamSource: GigEVirtualCameraExtensionStreamSource!
    private var _sinkStreamSource: GigEVirtualCameraExtensionSinkStreamSource!
    private var _streamingCounter: UInt32 = 0
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "DeviceSource")
    
    // Frame queue for receiving frames from main app
    private let frameQueue = DispatchQueue(label: "frameQueue", qos: .userInteractive)
    private var pendingFrames: [CMSampleBuffer] = []
    private let maxQueueSize = 3
    
    init(localizedName: String) {
        super.init()
        
        // Use a consistent device ID
        let deviceID = UUID(uuidString: "7A96E4B8-1A7B-4F8C-9E3D-5C2A8B4D9F0E")!
        self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)
        
        // Default format - will be updated when we receive frames
        let dims = CMVideoDimensions(width: 1920, height: 1080)
        var videoDescription: CMFormatDescription!
        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32BGRA,
            width: dims.width,
            height: dims.height,
            extensions: nil,
            formatDescriptionOut: &videoDescription
        )
        
        let videoStreamFormat = CMIOExtensionStreamFormat(
            formatDescription: videoDescription,
            maxFrameDuration: CMTime(value: 1, timescale: 30),
            minFrameDuration: CMTime(value: 1, timescale: 60),
            validFrameDurations: nil
        )
        
        // Create source stream (output from extension)
        let sourceStreamID = UUID(uuidString: "8B97F5C9-2B8C-5F9D-0F4E-6D3B9C5E0F1F")!
        _sourceStreamSource = GigEVirtualCameraExtensionStreamSource(
            localizedName: "GigE Camera Output",
            streamID: sourceStreamID,
            streamFormat: videoStreamFormat,
            device: device
        )
        
        // Create sink stream (input to extension)
        let sinkStreamID = UUID(uuidString: "9C08F6D0-3C9D-6F0E-1F5F-7E4C0D6F1F20")!
        _sinkStreamSource = GigEVirtualCameraExtensionSinkStreamSource(
            localizedName: "GigE Camera Input",
            streamID: sinkStreamID,
            streamFormat: videoStreamFormat,
            device: device,
            deviceSource: self
        )
        
        do {
            try device.addStream(_sourceStreamSource.stream)
            try device.addStream(_sinkStreamSource.stream)
        } catch {
            logger.error("Failed to add streams: \(error.localizedDescription)")
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.deviceTransportType, .deviceModel]
    }
    
    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
        if properties.contains(.deviceTransportType) {
            deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
        }
        if properties.contains(.deviceModel) {
            deviceProperties.model = "GigE Virtual Camera"
        }
        return deviceProperties
    }
    
    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
        // Handle settable properties here
    }
    
    func startStreaming() {
        _streamingCounter += 1
        logger.info("Start streaming, counter: \(self._streamingCounter)")
        
        // Start looking for frames from shared memory or XPC
        startReceivingFrames()
    }
    
    func stopStreaming() {
        if _streamingCounter > 1 {
            _streamingCounter -= 1
        } else {
            _streamingCounter = 0
            logger.info("Stop streaming")
            stopReceivingFrames()
        }
    }
    
    // MARK: - Frame Handling
    
    private func startReceivingFrames() {
        // This is where we'll receive frames from the main app
        // For now, let's set up the structure
        logger.info("Ready to receive frames from main app")
        
        // TODO: Set up XPC connection or shared memory to receive frames
        // For testing, we'll generate a test pattern
        generateTestPattern()
    }
    
    private func stopReceivingFrames() {
        frameQueue.sync {
            pendingFrames.removeAll()
        }
    }
    
    private func generateTestPattern() {
        // Temporary test pattern generation
        let timer = DispatchSource.makeTimerSource(queue: frameQueue)
        timer.schedule(deadline: .now(), repeating: 1.0/30.0)
        
        timer.setEventHandler { [weak self] in
            guard let self = self, self._streamingCounter > 0 else { return }
            
            // Create a simple colored frame
            let dims = CMVideoDimensions(width: 1920, height: 1080)
            var pixelBuffer: CVPixelBuffer?
            let pixelBufferAttributes: [String: Any] = [
                kCVPixelBufferWidthKey as String: dims.width,
                kCVPixelBufferHeightKey as String: dims.height,
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:] as NSDictionary
            ]
            
            CVPixelBufferCreate(kCFAllocatorDefault, Int(dims.width), Int(dims.height), kCVPixelFormatType_32BGRA, pixelBufferAttributes as CFDictionary, &pixelBuffer)
            
            if let pixelBuffer = pixelBuffer {
                CVPixelBufferLockBaseAddress(pixelBuffer, [])
                let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!
                let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
                
                // Fill with a color (blue-ish)
                let pixelData = baseAddress.assumingMemoryBound(to: UInt8.self)
                for y in 0..<Int(dims.height) {
                    for x in 0..<Int(dims.width) {
                        let offset = y * bytesPerRow + x * 4
                        pixelData[offset] = 100     // B
                        pixelData[offset + 1] = 50  // G
                        pixelData[offset + 2] = 50  // R
                        pixelData[offset + 3] = 255 // A
                    }
                }
                
                CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                
                // Create sample buffer
                var formatDescription: CMFormatDescription?
                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
                
                if let format = formatDescription {
                    var sampleBuffer: CMSampleBuffer?
                    var timingInfo = CMSampleTimingInfo()
                    timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
                    timingInfo.duration = CMTime(value: 1, timescale: 30)
                    
                    CMSampleBufferCreateForImageBuffer(
                        allocator: kCFAllocatorDefault,
                        imageBuffer: pixelBuffer,
                        dataReady: true,
                        makeDataReadyCallback: nil,
                        refcon: nil,
                        formatDescription: format,
                        sampleTiming: &timingInfo,
                        sampleBufferOut: &sampleBuffer
                    )
                    
                    if let sampleBuffer = sampleBuffer {
                        self.sendFrame(sampleBuffer)
                    }
                }
            }
        }
        
        timer.resume()
    }
    
    func sendFrame(_ sampleBuffer: CMSampleBuffer) {
        _sourceStreamSource.sendFrame(sampleBuffer)
    }
    
    func handleReceivedFrame(_ sampleBuffer: CMSampleBuffer) {
        // Forward the frame from sink to source
        sendFrame(sampleBuffer)
    }
}

// MARK: - Stream Source

class GigEVirtualCameraExtensionStreamSource: NSObject, CMIOExtensionStreamSource {
    
    private(set) var stream: CMIOExtensionStream!
    let device: CMIOExtensionDevice
    private let _streamFormat: CMIOExtensionStreamFormat
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "StreamSource")
    
    init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice) {
        self.device = device
        self._streamFormat = streamFormat
        super.init()
        self.stream = CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction: .source, clockType: .hostTime, source: self)
    }
    
    var formats: [CMIOExtensionStreamFormat] {
        return [_streamFormat]
    }
    
    var activeFormatIndex: Int = 0 {
        didSet {
            if activeFormatIndex >= formats.count {
                logger.error("Invalid format index")
            }
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.streamActiveFormatIndex, .streamFrameDuration]
    }
    
    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = activeFormatIndex
        }
        if properties.contains(.streamFrameDuration) {
            let frameDuration = CMTime(value: 1, timescale: 30)
            streamProperties.frameDuration = frameDuration
        }
        return streamProperties
    }
    
    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        if let activeFormatIndex = streamProperties.activeFormatIndex {
            self.activeFormatIndex = activeFormatIndex
        }
    }
    
    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        return true
    }
    
    func startStream() throws {
        guard let deviceSource = device.source as? GigEVirtualCameraExtensionDeviceSource else {
            throw NSError(domain: "GigEVirtualCamera", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid device source"])
        }
        deviceSource.startStreaming()
    }
    
    func stopStream() throws {
        guard let deviceSource = device.source as? GigEVirtualCameraExtensionDeviceSource else {
            throw NSError(domain: "GigEVirtualCamera", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid device source"])
        }
        deviceSource.stopStreaming()
    }
    
    func sendFrame(_ sampleBuffer: CMSampleBuffer) {
        let timing = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let hostTime = UInt64(timing.seconds * Double(NSEC_PER_SEC))
        stream.send(sampleBuffer, discontinuity: [], hostTimeInNanoseconds: hostTime)
    }
}

// MARK: - Provider Source

class GigEVirtualCameraExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
    
    private(set) var provider: CMIOExtensionProvider!
    private var deviceSource: GigEVirtualCameraExtensionDeviceSource!
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "Provider")
    
    init(clientQueue: DispatchQueue?) {
        super.init()
        
        provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
        deviceSource = GigEVirtualCameraExtensionDeviceSource(localizedName: "GigE Virtual Camera")
        
        do {
            try provider.addDevice(deviceSource.device)
            logger.info("Successfully added device to provider")
        } catch {
            logger.error("Failed to add device: \(error.localizedDescription)")
        }
    }
    
    func connect(to client: CMIOExtensionClient) throws {
        logger.info("Client connected: \(client)")
    }
    
    func disconnect(from client: CMIOExtensionClient) {
        logger.info("Client disconnected: \(client)")
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.providerManufacturer]
    }
    
    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = "Luke Chang"
        }
        return providerProperties
    }
    
    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
        // Handle settable properties here
    }
}

// MARK: - Sink Stream Source

class GigEVirtualCameraExtensionSinkStreamSource: NSObject, CMIOExtensionStreamSource {
    
    private(set) var stream: CMIOExtensionStream!
    let device: CMIOExtensionDevice
    private let _streamFormat: CMIOExtensionStreamFormat
    private weak var deviceSource: GigEVirtualCameraExtensionDeviceSource?
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "SinkStreamSource")
    
    init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice, deviceSource: GigEVirtualCameraExtensionDeviceSource) {
        self.device = device
        self._streamFormat = streamFormat
        self.deviceSource = deviceSource
        super.init()
        self.stream = CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction: .sink, clockType: .hostTime, source: self)
    }
    
    var formats: [CMIOExtensionStreamFormat] {
        return [_streamFormat]
    }
    
    var activeFormatIndex: Int = 0 {
        didSet {
            if activeFormatIndex >= formats.count {
                logger.error("Invalid format index")
            }
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.streamActiveFormatIndex, .streamFrameDuration, .streamSinkBufferQueueSize, .streamSinkBufferUnderrunCount]
    }
    
    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = activeFormatIndex
        }
        if properties.contains(.streamFrameDuration) {
            let frameDuration = CMTime(value: 1, timescale: 30)
            streamProperties.frameDuration = frameDuration
        }
        if properties.contains(.streamSinkBufferQueueSize) {
            streamProperties.sinkBufferQueueSize = 30
        }
        if properties.contains(.streamSinkBufferUnderrunCount) {
            streamProperties.sinkBufferUnderrunCount = 0
        }
        return streamProperties
    }
    
    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        if let activeFormatIndex = streamProperties.activeFormatIndex {
            self.activeFormatIndex = activeFormatIndex
        }
    }
    
    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        return true
    }
    
    func startStream() throws {
        logger.info("Sink stream started")
    }
    
    func stopStream() throws {
        logger.info("Sink stream stopped")
    }
    
    func consumeSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        logger.debug("Received frame in sink stream")
        deviceSource?.handleReceivedFrame(sampleBuffer)
    }
}