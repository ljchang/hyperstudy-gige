//
//  GigEVirtualCameraExtensionProvider.swift
//  GigEVirtualCameraExtension
//
//  CMIO Extension with custom properties for IOSurface sharing
//

import Foundation
import CoreMediaIO
import IOKit.audio
import IOSurface
import os.log

// MARK: - Frame Coordinator

class FrameCoordinator {
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "FrameCoordinator")
    private let appGroupID = "group.S368GH6KF7.com.lukechang.GigEVirtualCamera"
    private let surfaceIDsKey = "IOSurfaceIDs"
    private let frameIndexKey = "currentFrameIndex"
    
    private var groupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    func shareSurfaceIDs(_ surfaceIDs: [IOSurfaceID]) {
        print("🔵 FrameCoordinator.shareSurfaceIDs called with: \(surfaceIDs)")
        
        guard let defaults = groupDefaults else {
            logger.error("Failed to access App Group UserDefaults")
            print("❌ FrameCoordinator: Failed to access App Group UserDefaults!")
            return
        }
        
        let idArray = surfaceIDs.map { NSNumber(value: $0) }
        defaults.set(idArray, forKey: surfaceIDsKey)
        let success = defaults.synchronize()
        
        logger.info("Shared \(surfaceIDs.count) IOSurface IDs via App Groups: \(surfaceIDs)")
        print("🔵 FrameCoordinator: Shared \(surfaceIDs.count) IOSurface IDs, synchronize = \(success)")
        
        // Double-check it was saved
        if let saved = defaults.array(forKey: surfaceIDsKey) {
            print("🔵 FrameCoordinator: Verified save - found \(saved.count) IDs in UserDefaults")
        } else {
            print("❌ FrameCoordinator: Failed to verify save!")
        }
    }
    
    func clearSharedData() {
        guard let defaults = groupDefaults else { return }
        defaults.removeObject(forKey: surfaceIDsKey)
        defaults.removeObject(forKey: frameIndexKey)
        defaults.synchronize()
    }
    
    func readFrameIndex() -> Int {
        guard let defaults = groupDefaults else { return -1 }
        return defaults.integer(forKey: frameIndexKey)
    }
}

// MARK: - Shared Memory Frame Pool

class SharedMemoryFramePool {
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "FramePool")
    private let poolSize = 1  // Simplified to single buffer for debugging
    private var surfaces: [IOSurface] = []
    private var currentIndex = 0
    private let lock = NSLock()
    private let frameCoordinator = FrameCoordinator()
    
    init() {
        NSLog("🚀 GigEVirtualCamera: SharedMemoryFramePool initializing...")
        
        // Debug: Write to UserDefaults to verify init is called
        if let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera") {
            defaults.set("SharedMemoryFramePool init called at \(Date())", forKey: "Debug_PoolInit")
            defaults.synchronize()
        }
        
        createSurfacePool()
    }
    
    private func createSurfacePool() {
        NSLog("🟢 GigEVirtualCamera: createSurfacePool starting...")
        let width = 512
        let height = 512
        
        for i in 0..<poolSize {
            let properties: [String: Any] = [
                kIOSurfaceWidth as String: width,
                kIOSurfaceHeight as String: height,
                kIOSurfaceBytesPerElement as String: 4,
                kIOSurfaceBytesPerRow as String: width * 4,
                kIOSurfaceAllocSize as String: width * height * 4,
                kIOSurfacePixelFormat as String: kCVPixelFormatType_32BGRA,
                kIOSurfaceIsGlobal as String: true  // Make surface global for cross-process access
            ]
            
            if let surface = IOSurfaceCreate(properties as CFDictionary) {
                surfaces.append(surface)
                let surfaceID = IOSurfaceGetID(surface)
                NSLog("🟢 GigEVirtualCamera: Created IOSurface \(i+1)/\(self.poolSize) with ID: \(surfaceID)")
            } else {
                logger.error("❌ Failed to create IOSurface \(i+1)")
            }
        }
        
        // Share the IOSurface IDs via App Groups
        let surfaceIDs = surfaces.map { IOSurfaceGetID($0) }
        NSLog("🎯 GigEVirtualCamera: Sharing IOSurface IDs: \(surfaceIDs)")
        frameCoordinator.shareSurfaceIDs(surfaceIDs)
        NSLog("✅ GigEVirtualCamera: IOSurface IDs shared via App Groups - Total: \(surfaceIDs.count)")
        
        // Verify the write
        if let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera") {
            if let savedIDs = defaults.array(forKey: "IOSurfaceIDs") {
                logger.info("🟢 Verified IOSurface IDs saved to UserDefaults: \(savedIDs)")
            } else {
                logger.error("❌ Failed to verify IOSurface IDs in UserDefaults!")
            }
        }
    }
    
    func getNextSurface() -> IOSurface? {
        lock.lock()
        defer { lock.unlock() }
        
        guard !surfaces.isEmpty else { return nil }
        
        let surface = surfaces[currentIndex]
        currentIndex = (currentIndex + 1) % surfaces.count
        
        return surface
    }
    
    func getSurface(at index: Int) -> IOSurface? {
        lock.lock()
        defer { lock.unlock() }
        
        guard index >= 0 && index < surfaces.count else { return nil }
        return surfaces[index]
    }
    
    func getSurfaceID(at index: Int) -> IOSurfaceID {
        lock.lock()
        defer { lock.unlock() }
        
        guard index < surfaces.count else { return 0 }
        return IOSurfaceGetID(surfaces[index])
    }
    
    func getSurfaceIDs() -> [IOSurfaceID] {
        lock.lock()
        defer { lock.unlock() }
        
        return surfaces.map { IOSurfaceGetID($0) }
    }
}

// MARK: - Device Source

class GigEVirtualCameraExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource {
    private(set) var device: CMIOExtensionDevice!
    
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "Device")
    private var _streamingCounter = 0
    private var _sourceStreamSource: GigEVirtualCameraExtensionStreamSource!
    let framePool: SharedMemoryFramePool  // Shared frame pool
    
    init(localizedName: String) {
        // Initialize frame pool FIRST before super.init()
        print("🎬 GigEVirtualCameraExtensionDeviceSource: Creating SharedMemoryFramePool...")
        self.framePool = SharedMemoryFramePool()
        
        super.init()
        
        print("🎬 GigEVirtualCameraExtensionDeviceSource: Initializing device...")
        
        let deviceID = UUID(uuidString: "4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4")!
        self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)
        
        logger.info("Device initialized: \(localizedName)")
        print("✅ Device initialized: \(localizedName)")
        
        // Create video format that matches what the GigE camera provides
        var formatDict: [String: Any] = [:]
        formatDict[kCVPixelBufferPixelFormatTypeKey as String] = kCVPixelFormatType_32BGRA
        formatDict[kCVPixelBufferWidthKey as String] = 512
        formatDict[kCVPixelBufferHeightKey as String] = 512
        formatDict[kCVPixelBufferIOSurfacePropertiesKey as String] = [String: Any]()
        
        var videoDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32BGRA,
            width: 512,
            height: 512,
            extensions: formatDict as CFDictionary,
            formatDescriptionOut: &videoDescription
        )
        
        guard let videoDesc = videoDescription else {
            logger.error("Failed to create video format description")
            return
        }
        
        let videoStreamFormat = CMIOExtensionStreamFormat(
            formatDescription: videoDesc,
            maxFrameDuration: CMTime(value: 1, timescale: 30),  // 30 fps
            minFrameDuration: CMTime(value: 1, timescale: 30),  // Fixed 30 fps
            validFrameDurations: nil
        )
        
        // Create source stream
        let sourceStreamID = UUID(uuidString: "8B97F5C9-2B8C-5F9D-0F4E-6D3B9C5E0F1F")!
        _sourceStreamSource = GigEVirtualCameraExtensionStreamSource(
            localizedName: "GigE Camera Output",
            streamID: sourceStreamID,
            streamFormat: videoStreamFormat,
            device: device,
            framePool: framePool
        )
        
        do {
            try device.addStream(_sourceStreamSource.stream)
            logger.info("✅ Added source stream to device")
        } catch {
            logger.error("Failed to add stream: \(error.localizedDescription)")
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
        // These properties are read-only
    }
    
    func startStreaming() {
        _streamingCounter += 1
        logger.info("Start streaming, counter: \(self._streamingCounter)")
    }
    
    func stopStreaming() {
        if _streamingCounter > 1 {
            _streamingCounter -= 1
        } else {
            _streamingCounter = 0
            logger.info("Stop streaming")
        }
    }
}

// MARK: - Stream Source

class GigEVirtualCameraExtensionStreamSource: NSObject, CMIOExtensionStreamSource {
    
    private(set) var stream: CMIOExtensionStream!
    let device: CMIOExtensionDevice
    private let _streamFormat: CMIOExtensionStreamFormat
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "StreamSource")
    
    // Frame handling
    private let framePool: SharedMemoryFramePool
    private var timer: Timer?
    private let frameDuration = CMTime(value: 1, timescale: 30)  // 30 fps
    private var frameCount: UInt64 = 0
    private var lastFrameIndex: Int = -1
    private let frameCoordinator = FrameCoordinator()
    
    init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice, framePool: SharedMemoryFramePool) {
        self.device = device
        self._streamFormat = streamFormat
        self.framePool = framePool
        super.init()
        self.stream = CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction: .source, clockType: .hostTime, source: self)
        
        // Log the IOSurface IDs for debugging
        let surfaceIDs = framePool.getSurfaceIDs()
        logger.info("Stream initialized with IOSurfaces: \(surfaceIDs)")
    }
    
    var formats: [CMIOExtensionStreamFormat] {
        return [_streamFormat]
    }
    
    var activeFormatIndex: Int = 0
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.streamActiveFormatIndex, .streamFrameDuration]
    }
    
    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = activeFormatIndex
        }
        if properties.contains(.streamFrameDuration) {
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
        NSLog("🎬 GigEVirtualCamera: startStream() called!")
        
        // Write to shared data as a debug marker
        if let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera") {
            defaults.set("Stream started at \(Date())", forKey: "Debug_StreamStarted")
            defaults.synchronize()
        }
        
        guard let deviceSource = device.source as? GigEVirtualCameraExtensionDeviceSource else {
            NSLog("❌ GigEVirtualCamera: Failed to get device source")
            throw NSError(domain: "GigEVirtualCamera", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid device source"])
        }
        deviceSource.startStreaming()
        
        NSLog("🟢 GigEVirtualCamera: Stream started - will check for frames at 30fps")
        NSLog("GigEVirtualCamera: IOSurface IDs: \(self.framePool.getSurfaceIDs())")
        
        // Start timer to send frames - ensure it's on the main run loop
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            self?.sendNextFrame()
        }
        
        // Ensure timer is added to current run loop
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
            logger.info("Timer scheduled on run loop")
        }
        
        // Send first frame immediately
        sendNextFrame()
    }
    
    func stopStream() throws {
        // Write to shared data as a debug marker
        if let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera") {
            defaults.set("Stream stopped at \(Date())", forKey: "Debug_StreamStopped")
            defaults.synchronize()
        }
        
        guard let deviceSource = device.source as? GigEVirtualCameraExtensionDeviceSource else {
            throw NSError(domain: "GigEVirtualCamera", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid device source"])
        }
        deviceSource.stopStreaming()
        
        timer?.invalidate()
        timer = nil
        
        NSLog("GigEVirtualCamera: Stream stopped")
    }
    
    private func sendNextFrame() {
        // Check if there's a new frame from the app
        let currentFrameIndex = frameCoordinator.readFrameIndex()
        
        // Log frame check periodically (every 30 frames = ~1 second)
        if frameCount % 30 == 0 {
            NSLog("GigEVirtualCamera: Checking frame: current=\(currentFrameIndex), last=\(self.lastFrameIndex)")
            
            // Also log the IOSurface IDs we're monitoring
            if frameCount % 300 == 0 {  // Every 10 seconds
                let surfaceIDs = framePool.getSurfaceIDs()
                NSLog("GigEVirtualCamera: Monitoring IOSurface: \(surfaceIDs)")
            }
        }
        
        // If no frame written yet or same frame, use test pattern
        if currentFrameIndex <= 0 || currentFrameIndex == lastFrameIndex {
            // No new frame, send test pattern for now
            if frameCount % 300 == 0 {
                NSLog("GigEVirtualCamera: No new frame, sending test pattern")
            }
            sendTestPattern()
            return
        }
        
        // New frame available!
        NSLog("GigEVirtualCamera: 🎉 New frame available! Frame \(currentFrameIndex)")
        lastFrameIndex = currentFrameIndex
        
        // Simplified: always use the single IOSurface at index 0
        let surfaceIndex = 0
        guard let ioSurface = framePool.getSurface(at: surfaceIndex) else {
            logger.error("No IOSurface available at index \(surfaceIndex)")
            return
        }
        
        // Create CVPixelBuffer from IOSurface
        var unmanagedPixelBuffer: Unmanaged<CVPixelBuffer>?
        let result = CVPixelBufferCreateWithIOSurface(
            kCFAllocatorDefault,
            ioSurface,
            [
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey: 512,  // Match actual frame size
                kCVPixelBufferHeightKey: 512,
                kCVPixelBufferIOSurfacePropertiesKey: [:]
            ] as CFDictionary,
            &unmanagedPixelBuffer
        )
        
        guard result == kCVReturnSuccess, let unmanagedBuffer = unmanagedPixelBuffer else {
            logger.error("Failed to create pixel buffer from IOSurface: \(result)")
            return
        }
        
        let pixelBuffer = unmanagedBuffer.takeRetainedValue()
        NSLog("GigEVirtualCamera: Created pixel buffer from IOSurface, sending...")
        sendPixelBuffer(pixelBuffer)
    }
    
    private func sendTestPattern() {
        // Create a simple test pattern when no real frames are available
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: 512,
            kCVPixelBufferHeightKey: 512,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ]
        
        CVPixelBufferCreate(kCFAllocatorDefault, 512, 512, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        
        guard let buffer = pixelBuffer else { return }
        
        // Fill with a simple gradient pattern
        CVPixelBufferLockBaseAddress(buffer, [])
        if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
            let width = CVPixelBufferGetWidth(buffer)
            let height = CVPixelBufferGetHeight(buffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            let pixelData = baseAddress.assumingMemoryBound(to: UInt8.self)
            
            for y in 0..<height {
                for x in 0..<width {
                    let offset = y * bytesPerRow + x * 4
                    // Create a gradient pattern
                    pixelData[offset] = UInt8((x * 255) / width)      // B
                    pixelData[offset + 1] = UInt8((y * 255) / height) // G
                    pixelData[offset + 2] = 128                       // R
                    pixelData[offset + 3] = 255                       // A
                }
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        sendPixelBuffer(buffer)
    }
    
    private func sendPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        frameCount += 1
        
        // Create timing info
        let now = CMClockGetTime(CMClockGetHostTimeClock())
        var timingInfo = CMSampleTimingInfo(
            duration: frameDuration,
            presentationTimeStamp: now,
            decodeTimeStamp: .invalid
        )
        
        // Create format description from the pixel buffer
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
        let result = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: format,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        guard result == kCVReturnSuccess, let sample = sampleBuffer else {
            logger.error("Failed to create sample buffer: \(result)")
            return
        }
        
        // Log frame info periodically
        if frameCount % 30 == 1 {
            var surfaceID: IOSurfaceID = 0
            if let ioSurfaceRef = CVPixelBufferGetIOSurface(pixelBuffer) {
                surfaceID = IOSurfaceGetID(ioSurfaceRef.takeUnretainedValue())
            }
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            logger.info("📤 Frame #\(self.frameCount) | \(width)x\(height) | IOSurface: \(surfaceID)")
        }
        
        // Send to CMIO
        stream.send(sample, discontinuity: [], hostTimeInNanoseconds: UInt64(now.seconds * Double(NSEC_PER_SEC)))
    }
}

// MARK: - Provider Source

class GigEVirtualCameraExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
    
    private(set) var provider: CMIOExtensionProvider!
    private var deviceSource: GigEVirtualCameraExtensionDeviceSource!
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "Provider")
    
    override init() {
        super.init()
        
        NSLog("🟡 GigEVirtualCamera: Provider init starting...")
        
        // Debug: Write to UserDefaults to verify provider init
        if let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera") {
            defaults.set("Provider init at \(Date())", forKey: "Debug_ProviderInit")
            defaults.synchronize()
            NSLog("🟡 GigEVirtualCamera: Written Debug_ProviderInit to UserDefaults")
        }
        
        provider = CMIOExtensionProvider(source: self, clientQueue: nil)
        NSLog("🟡 GigEVirtualCamera: Creating device source...")
        deviceSource = GigEVirtualCameraExtensionDeviceSource(localizedName: "GigE Virtual Camera")
        NSLog("🟡 GigEVirtualCamera: Device source created")
        
        do {
            try provider.addDevice(deviceSource.device)
            NSLog("✅ GigEVirtualCamera: Provider initialized with device")
        } catch {
            NSLog("❌ GigEVirtualCamera: Failed to add device: \(error.localizedDescription)")
        }
    }
    
    func connect(to client: CMIOExtensionClient) throws {
        NSLog("🔗 GigEVirtualCamera: Client connected: PID \(client.pid)")
    }
    
    func disconnect(from client: CMIOExtensionClient) {
        NSLog("🔗 GigEVirtualCamera: Client disconnected: PID \(client.pid)")
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        return [.providerManufacturer]
    }
    
    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = "HyperStudy"
        }
        return providerProperties
    }
    
    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
        // Handle settable properties here
    }
}