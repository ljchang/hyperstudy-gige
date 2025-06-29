//
//  CameraManager.swift
//  GigEVirtualCamera
//
//  Created on 6/24/25.
//

import Foundation
import SwiftUI
import os.log

@MainActor
class CameraManager: NSObject, ObservableObject {
    static let shared = CameraManager()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var isExtensionInstalled = false
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
    private let cmioFrameSender = CMIOFrameSender()
    private var isFrameSenderConnected = false
    
    // MARK: - Computed Properties
    var statusText: String {
        if isConnected {
            return "Connected"
        } else if isExtensionInstalled {
            return "No Camera"
        } else {
            return "Extension Not Installed"
        }
    }
    
    var statusColor: Color {
        if isConnected {
            return DesignSystem.Colors.statusGreen
        } else if isExtensionInstalled {
            return DesignSystem.Colors.statusOrange
        } else {
            return DesignSystem.Colors.textSecondary
        }
    }
    
    private let logger = Logger(subsystem: CameraConstants.BundleID.app, category: "CameraManager")
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupNotifications()
        setupFrameSender()
        // Delay checking extension status to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkExtensionStatus()
        }
    }
    
    // MARK: - Extension Management
    // CMIOExtensions are automatically loaded when app is in /Applications
    // No manual installation/uninstallation needed
    
    // MARK: - Private Methods
    private func checkExtensionStatus() {
        // CMIOExtensions are automatically loaded when app is in /Applications
        // No need for system extension activation
        
        // Check if we're running from /Applications
        let appPath = Bundle.main.bundlePath
        if appPath.hasPrefix("/Applications/") {
            logger.info("Running from /Applications - CMIOExtension should be available")
            isExtensionInstalled = true
            UserDefaults.standard.set(true, forKey: CameraConstants.UserDefaultsKeys.isExtensionInstalled)
        } else {
            logger.warning("Not running from /Applications - CMIOExtension may not load")
            logger.warning("Current path: \(appPath)")
            isExtensionInstalled = false
        }
        
        checkCameraConnection()
    }
    
    
    private func checkCameraConnection() {
        // Check actual camera connection through GigECameraManager
        let gigEManager = GigECameraManager.shared
        
        // Update available cameras
        availableCameras = gigEManager.availableCameras
        
        if gigEManager.isConnected, let camera = gigEManager.currentCamera {
            cameraModel = camera.modelName
            isConnected = true
            selectedCameraId = camera.deviceId
            
            // Save for next launch
            UserDefaults.standard.set(camera.modelName, forKey: CameraConstants.UserDefaultsKeys.lastConnectedCamera)
        } else {
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
    
    // MARK: - Preview Methods
    func togglePreview() {
        if isShowingPreview {
            hidePreview()
        } else {
            showPreview()
        }
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
        // Try to connect to the virtual camera extension
        connectFrameSender()
        
        // Set up frame handler to send frames to extension
        let gigEManager = GigECameraManager.shared
        gigEManager.addFrameHandler { [weak self] pixelBuffer in
            self?.cmioFrameSender.sendFrame(pixelBuffer)
        }
    }
    
    private func connectFrameSender() {
        // Try to connect in background
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Wait a bit for the extension to be ready
            Thread.sleep(forTimeInterval: 1.0)
            
            if self.cmioFrameSender.connect() {
                self.isFrameSenderConnected = true
                self.logger.info("Successfully connected to CMIO extension")
            } else {
                self.logger.warning("Failed to connect to CMIO extension - will show test pattern")
                
                // Retry after a delay
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5.0) {
                    self.connectFrameSender()
                }
            }
        }
    }
}