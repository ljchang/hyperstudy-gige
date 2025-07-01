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
    
    // MARK: - Private Properties
    private let frameSender = CMIOFrameSender()
    @Published private(set) var isFrameSenderConnected = false
    private var frameCount: Int = 0
    
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
        setupNotifications()
        setupFrameSender()
        
        // Check for available cameras after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkCameraConnection()
        }
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
            
            // Try to reconnect to CMIO extension when camera connects
            Task { @MainActor in
                if !isFrameSenderConnected {
                    logger.info("Camera connected, retrying CMIO extension connection...")
                    connectFrameSender()
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
        } else {
            isConnected = false
            if gigEManager.currentCamera == nil && selectedCameraId != nil {
                selectedCameraId = nil
            }
        }
    }
    
    @objc private func handleManualTrigger() {
        logger.info("Manual trigger received - attempting frame sender connection")
        connectFrameSender()
        
        // If connected to camera but not streaming, start streaming
        if isConnected && !GigECameraManager.shared.isStreaming {
            logger.info("Starting camera streaming...")
            GigECameraManager.shared.startStreaming()
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
        logger.info("Manually retrying frame sender connection...")
        connectFrameSender()
    }
    
    func testXPCConnection() {
        logger.info("Testing CMIO sink connection...")
        
        // Disconnect first if connected
        if isFrameSenderConnected {
            frameSender.disconnect()
            isFrameSenderConnected = false
        }
        
        // Try to connect
        if frameSender.connect() {
            isFrameSenderConnected = true
            logger.info("CMIO sink connection successful!")
            
            // Start streaming if camera is connected
            if isConnected && !GigECameraManager.shared.isStreaming {
                logger.info("Starting camera streaming after sink connection...")
                GigECameraManager.shared.startStreaming()
            }
            
            // Try sending a test frame
            sendTestFrame()
        } else {
            isFrameSenderConnected = false
            logger.error("CMIO sink connection failed - virtual camera not found or sink stream not available")
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
        frameSender.sendFrame(testBuffer)
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
    
    // MARK: - CMIO Frame Sender
    private func setupFrameSender() {
        // Delay initial connection attempt to allow extension to fully initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            
            print("[CameraManager] Attempting initial connection to virtual camera sink stream...")
            self.logger.info("Attempting initial connection to virtual camera sink stream...")
            if self.frameSender.connect() {
                self.isFrameSenderConnected = true
                print("[CameraManager] ✅ Connected to virtual camera sink stream")
                self.logger.info("✅ Connected to virtual camera sink stream")
            } else {
                self.isFrameSenderConnected = false
                print("[CameraManager] ⚠️ Failed to connect to virtual camera sink stream - extension may not be ready")
                self.logger.warning("⚠️ Failed to connect to virtual camera sink stream - extension may not be ready")
                
                // Try again after another delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    guard let self = self else { return }
                    print("[CameraManager] Retrying connection to virtual camera...")
                    self.logger.info("Retrying connection to virtual camera...")
                    self.connectFrameSender()
                }
            }
        }
        
        // Set up periodic retry for sink stream connection
        // This is needed because Photo Booth may start the stream at any time
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if !self.isFrameSenderConnected {
                    self.logger.info("Periodic retry: Attempting to connect to sink stream...")
                    self.connectFrameSender()
                }
            }
        }
        
        // Set up frame handler to send frames to extension
        let gigEManager = GigECameraManager.shared
        gigEManager.addFrameHandler { [weak self] pixelBuffer in
            guard let self = self else { return }
            
            // Only send if connected
            if self.isFrameSenderConnected {
                self.frameSender.sendFrame(pixelBuffer)
                self.frameCount += 1
            }
        }
    }
    
    private func connectFrameSender() {
        // Try to connect to the sink stream
        if frameSender.connect() {
            isFrameSenderConnected = true
            logger.info("Reconnected to virtual camera sink stream")
            
            // If we have a camera connected and not streaming, start streaming
            if isConnected && !GigECameraManager.shared.isStreaming {
                logger.info("Starting camera streaming after sink connection...")
                GigECameraManager.shared.startStreaming()
            }
        } else {
            isFrameSenderConnected = false
            logger.error("Failed to reconnect to virtual camera sink stream")
        }
    }
}