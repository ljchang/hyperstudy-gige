//
//  CameraManager.swift
//  GigEVirtualCamera
//
//  Created on 6/24/25.
//

import Foundation
import SwiftUI
import Combine
import os.log

// UserDefaults extension for KVO
extension UserDefaults {
    @objc dynamic var StreamState: [String: Any]? {
        return dictionary(forKey: "StreamState")
    }
}

@MainActor
class CameraManager: NSObject, ObservableObject {
    static let shared = CameraManager()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var cameraModel = "Unknown"
    @Published var currentFormat = "1920×1080 @ 30fps"
    @Published var availableCameras: [AravisCamera] = []
    @Published var currentPixelFormat = "Auto" {
        didSet {
            // Update the GigECameraManager when format changes
            if currentPixelFormat != oldValue {
                let gigEManager = GigECameraManager.shared
                gigEManager.setPixelFormat(currentPixelFormat)
                logger.info("Changed pixel format to: \(self.currentPixelFormat)")
            }
        }
    }
    @Published var availablePixelFormats = ["Auto", "Bayer GR8", "Bayer RG8", "Bayer GB8", "Bayer BG8", "Mono8", "RGB8"]
    @Published var selectedCameraId: String? = nil {
        didSet {
            // Only connect if the selection actually changed and we're not already connected to this camera
            if selectedCameraId != oldValue {
                if let cameraId = selectedCameraId {
                    let gigEManager = GigECameraManager.shared
                    if gigEManager.currentCamera?.deviceId != cameraId {
                        connectToCamera(withId: cameraId)
                    }
                } else {
                    disconnectCamera()
                }
            }
        }
    }
    @Published var isShowingPreview = false
    @Published var isFrameSenderConnected = false  // Will be set true when sink connects
    
    // MARK: - Private Properties
    private let sinkConnector = CMIOSinkConnector()
    private var frameCount: Int = 0
    private var streamStateObserver: NSKeyValueObservation?
    private let appGroupDefaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera")
    
    // MARK: - Computed Properties
    var statusText: String {
        if isConnected {
            return "Connected"
        } else {
            return "No Camera"
        }
    }
    
    var statusColor: Color {
        if isConnected {
            return DesignSystem.Colors.statusGreen
        } else {
            return DesignSystem.Colors.statusOrange
        }
    }
    
    private let logger = Logger(subsystem: CameraConstants.BundleID.app, category: "CameraManager")
    
    // MARK: - Initialization
    private override init() {
        super.init()
        logger.info("CameraManager init called")
        setupNotifications()
        setupFrameHandler()  // Set up frame handler for IOSurface writer
        
        // Check for available cameras after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkCameraConnection()
        }
    }
    
    deinit {
        streamStateObserver?.invalidate()
    }
    
    // MARK: - Private Methods
    private var cancellables = Set<AnyCancellable>()
    
    
    private func checkCameraConnection() {
        print("CameraManager: checkCameraConnection() called")
        
        // Check actual camera connection through GigECameraManager
        let gigEManager = GigECameraManager.shared
        
        print("CameraManager: GigECameraManager.isConnected = \(gigEManager.isConnected)")
        print("CameraManager: GigECameraManager.availableCameras.count = \(gigEManager.availableCameras.count)")
        
        // Update available cameras
        availableCameras = gigEManager.availableCameras
        
        if gigEManager.isConnected, let camera = gigEManager.currentCamera {
            print("CameraManager: Connected to camera: \(camera.modelName)")
            cameraModel = camera.modelName
            isConnected = true
            selectedCameraId = camera.deviceId
            
            // Save for next launch
            UserDefaults.standard.set(camera.modelName, forKey: CameraConstants.UserDefaultsKeys.lastConnectedCamera)
        } else {
            print("CameraManager: Not connected, triggering camera discovery...")
            isConnected = false
            
            // Try to discover cameras
            gigEManager.discoverCameras()
        }
        
        // Listen for camera list updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCameraListUpdate),
            name: NSNotification.Name("GigECamerasDiscovered"),
            object: nil
        )
    }
    
    private func connectToCamera(withId cameraId: String) {
        let gigEManager = GigECameraManager.shared
        
        if let camera = availableCameras.first(where: { $0.deviceId == cameraId }) {
            gigEManager.connect(to: camera)
            
            // Always auto-start streaming after connection - this follows the producer model
            // The app should always be producing frames when connected
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if gigEManager.isConnected && !gigEManager.isStreaming {
                    self.logger.info("Auto-starting streaming after connection (producer model)...")
                    gigEManager.startStreaming()
                }
            }
        }
    }
    
    private func disconnectCamera() {
        let gigEManager = GigECameraManager.shared
        gigEManager.disconnect()
        isConnected = false
        cameraModel = "Unknown"
    }
    
    @objc private func handleCameraListUpdate() {
        let gigEManager = GigECameraManager.shared
        availableCameras = gigEManager.availableCameras
        
        // Auto-select if only one camera is available and none is selected
        if availableCameras.count == 1 && selectedCameraId == nil {
            selectedCameraId = availableCameras[0].deviceId
        }
    }
    
    private func setupNotifications() {
        // Listen for camera connection notifications from extension
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCameraConnection(_:)),
            name: CameraConstants.Notifications.cameraDidConnect,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCameraDisconnection(_:)),
            name: CameraConstants.Notifications.cameraDidDisconnect,
            object: nil
        )
        
        // Listen for GigECameraManager state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGigECameraStateChange),
            name: NSNotification.Name("GigECameraStateChanged"),
            object: nil
        )
        
        // Listen for manual trigger to connect frame sender
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleManualTrigger),
            name: NSNotification.Name("TriggerFrameSenderConnection"),
            object: nil
        )
        
        // Monitor App Group UserDefaults for stream state changes
        if let defaults = appGroupDefaults {
            // Use KVO to monitor changes
            streamStateObserver = defaults.observe(\.StreamState, options: [.new, .initial]) { [weak self] _, _ in
                self?.handleStreamStateChange()
            }
            
            // Also use notification as backup
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleStreamStateChange),
                name: UserDefaults.didChangeNotification,
                object: defaults
            )
            
            // Check initial state
            handleStreamStateChange()
        }
    }
    
    @objc private func handleCameraConnection(_ notification: Notification) {
        if let info = notification.userInfo,
           let model = info["model"] as? String {
            cameraModel = model
            isConnected = true
            
            // Save for next launch
            UserDefaults.standard.set(model, forKey: CameraConstants.UserDefaultsKeys.lastConnectedCamera)
        }
    }
    
    @objc private func handleCameraDisconnection(_ notification: Notification) {
        isConnected = false
    }
    
    @objc private func handleGigECameraStateChange() {
        let gigEManager = GigECameraManager.shared
        
        if gigEManager.isConnected, let camera = gigEManager.currentCamera {
            isConnected = true
            cameraModel = camera.modelName
            // Only update selectedCameraId if it's different to avoid triggering reconnection
            if selectedCameraId != camera.deviceId {
                selectedCameraId = camera.deviceId
            }
            
            // Auto-start streaming if connected but not streaming (producer model)
            if !gigEManager.isStreaming {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if gigEManager.isConnected && !gigEManager.isStreaming {
                        self.logger.info("Auto-starting streaming on state change (producer model)...")
                        gigEManager.startStreaming()
                    }
                }
            }
        } else {
            isConnected = false
            if gigEManager.currentCamera == nil && selectedCameraId != nil {
                selectedCameraId = nil
            }
        }
    }
    
    @objc private func handleManualTrigger() {
        logger.info("Manual trigger received - starting streaming")
        
        // If connected to camera but not streaming, start streaming
        if isConnected && !GigECameraManager.shared.isStreaming {
            logger.info("Starting camera streaming...")
            GigECameraManager.shared.startStreaming()
        }
    }
    
    @objc private func handleStreamStateChange() {
        // Check if extension is requesting frames
        guard let defaults = UserDefaults(suiteName: "group.S368GH6KF7.com.lukechang.GigEVirtualCamera"),
              let state = defaults.dictionary(forKey: "StreamState"),
              let isActive = state["streamActive"] as? Bool else {
            return
        }
        
        if isActive {
            logger.info("Extension requesting frames")
            
            // The property listener will handle sink connection automatically
            // We just need to ensure Aravis is streaming
            if isConnected && !GigECameraManager.shared.isStreaming {
                logger.info("Starting Aravis streaming in response to extension request")
                GigECameraManager.shared.startStreaming()
            }
        } else {
            logger.info("Extension stopped requesting frames")
            // Optionally stop streaming
            if GigECameraManager.shared.isStreaming {
                logger.info("Stopping Aravis streaming")
                GigECameraManager.shared.stopStreaming()
            }
        }
    }
    
    // MARK: - Preview Methods
    func togglePreview() {
        if isShowingPreview {
            hidePreview()
        } else {
            showPreview()
        }
    }
    
    // MARK: - Public Methods for Frame Sender
    func retryFrameSenderConnection() {
        logger.info("Retrying CMIO sink connection...")
        
        // With property listeners, we just need to restart the listener
        sinkConnector.disconnect()
        
        // The property listener will automatically detect and connect when sink is available
        logger.info("Property listener will automatically reconnect when sink stream is available")
    }
    
    func testSinkStreamConnection() {  // Keep method name for compatibility
        logger.info("Testing CMIO sink stream connection...")
        
        // The property listener handles connection automatically
        if isFrameSenderConnected {
            logger.info("✅ Already connected to sink stream via property listener")
            sendTestFrame()
        } else {
            logger.info("⏳ Waiting for sink stream discovery via property listener...")
        }
    }
    
    private func sendTestFrame() {
        // Create a test pixel buffer
        let width = 640
        let height = 480
        guard let testBuffer = PixelBufferHelpers.createIOSurfaceBackedPixelBuffer(
            width: width,
            height: height,
            pixelFormat: kCVPixelFormatType_32BGRA
        ) else {
            logger.error("Failed to create test pixel buffer")
            return
        }
        
        // Fill with test pattern
        CVPixelBufferLockBaseAddress(testBuffer, [])
        if let baseAddress = CVPixelBufferGetBaseAddress(testBuffer) {
            let bytesPerRow = CVPixelBufferGetBytesPerRow(testBuffer)
            let pixelData = baseAddress.assumingMemoryBound(to: UInt8.self)
            
            for y in 0..<height {
                for x in 0..<width {
                    let offset = y * bytesPerRow + x * 4
                    pixelData[offset] = 255     // B
                    pixelData[offset + 1] = 0   // G  
                    pixelData[offset + 2] = 0   // R
                    pixelData[offset + 3] = 255 // A
                }
            }
        }
        CVPixelBufferUnlockBaseAddress(testBuffer, [])
        
        logger.info("Sending test frame...")
        sinkConnector.sendFrame(testBuffer)
    }
    
    private func showPreview() {
        guard isConnected else { 
            logger.warning("Cannot show preview: Not connected to camera")
            return 
        }
        
        isShowingPreview = true
        logger.info("Showing embedded preview for camera: \(self.cameraModel)")
        
        // The actual preview is handled by the CameraPreviewSection in ContentView
        // We just need to set the flag here
    }
    
    func hidePreview() {
        isShowingPreview = false
        logger.info("Hiding embedded preview")
        
        // The actual cleanup is handled by the CameraPreviewSection's onDisappear
    }
    
    // MARK: - Frame Handler Setup
    private func setupFrameHandler() {
        // Set up frame handler to send frames to extension
        let gigEManager = GigECameraManager.shared
        gigEManager.addFrameHandler { [weak self] pixelBuffer in
            guard let self = self else { return }
            
            // Send frame through CMIO sink if connected
            if self.isFrameSenderConnected {
                self.sinkConnector.sendFrame(pixelBuffer)
                self.frameCount += 1
                
                // Log first frame and periodic updates
                if self.frameCount == 1 {
                    self.logger.info("First frame sent to CMIO sink!")
                } else if self.frameCount % 300 == 0 {
                    self.logger.info("Sent \(self.frameCount) frames to CMIO sink")
                }
            } else {
                // Log why we're not sending
                if self.frameCount % 30 == 0 {
                    self.logger.warning("Not sending frames - isFrameSenderConnected = false")
                }
            }
        }
        
        // Set up callbacks for automatic sink connection
        setupSinkConnectorCallbacks()
        
        // Start the connection process
        logger.info("Starting sink connector connection...")
        let connected = sinkConnector.connect()
        logger.info("Initial sink connector connect returned: \(connected)")
        
        logger.info("Frame handler setup complete - waiting for sink stream discovery")
    }
    
    private func setupSinkConnectorCallbacks() {
        // Called when sink stream becomes available
        sinkConnector.onSinkStreamAvailable = { [weak self] available in
            guard let self = self else { return }
            
            self.logger.info("Sink stream availability changed: \(available)")
            
            if available && self.isConnected && !GigECameraManager.shared.isStreaming {
                self.logger.info("Sink stream available - starting Aravis streaming automatically")
                GigECameraManager.shared.startStreaming()
            }
        }
        
        // Called when connection state changes
        sinkConnector.onConnectionStateChanged = { [weak self] connected in
            guard let self = self else { return }
            
            self.isFrameSenderConnected = connected
            
            if connected {
                self.logger.info("✅ Sink connector connected via property listener callback!")
                
                // Start Aravis streaming if camera is connected but not streaming
                if self.isConnected && !GigECameraManager.shared.isStreaming {
                    self.logger.info("Starting Aravis streaming after sink connection")
                    GigECameraManager.shared.startStreaming()
                }
            } else {
                self.logger.warning("⚠️ Sink connector disconnected")
            }
        }
    }
    
    func getPerformanceMetrics() -> (fps: Double, framesTotal: UInt64, framesDropped: UInt64) {
        // For now, return basic metrics from frame count
        return (30.0, UInt64(frameCount), 0)
    }
}