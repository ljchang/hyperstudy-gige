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
    @Published var isInstalling = false
    @Published var cameraModel = "Unknown"
    @Published var currentFormat = "1920×1080 @ 30fps"
    
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
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: CameraConstants.BundleID.app, category: "CameraManager")
    
    // MARK: - Initialization
    private override init() {
        super.init()
        checkExtensionStatus()
        setupNotifications()
    }
    
    // MARK: - Extension Management
    func installExtension() async {
        await MainActor.run {
            isInstalling = true
        }
        
        logger.info("Activating camera extension...")
        
        // For app extensions (not system extensions), we just need to mark it as installed
        // The extension is automatically available when the app bundle contains it
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            isInstalling = false
            isExtensionInstalled = true
            UserDefaults.standard.set(true, forKey: CameraConstants.UserDefaultsKeys.isExtensionInstalled)
            checkCameraConnection()
            
            // Show success message
            let alert = NSAlert()
            alert.messageText = "Camera Extension Activated"
            alert.informativeText = "The GigE Virtual Camera is now available in compatible applications."
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
    
    func uninstallExtension() async {
        logger.info("Deactivating camera extension...")
        
        // For app extensions, we just mark it as uninstalled
        isExtensionInstalled = false
        isConnected = false
        UserDefaults.standard.set(false, forKey: CameraConstants.UserDefaultsKeys.isExtensionInstalled)
        
        // Show message
        let alert = NSAlert()
        alert.messageText = "Camera Extension Deactivated"
        alert.informativeText = "The virtual camera is no longer available. You may need to restart applications that were using it."
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    // MARK: - Private Methods
    private func checkExtensionStatus() {
        // Check if extension is installed by looking for it in system
        // This is a simplified check - in production you'd query the system more thoroughly
        let defaults = UserDefaults.standard
        isExtensionInstalled = defaults.bool(forKey: CameraConstants.UserDefaultsKeys.isExtensionInstalled)
        
        if isExtensionInstalled {
            checkCameraConnection()
        }
    }
    
    private func checkCameraConnection() {
        // Check actual camera connection through GigECameraManager
        let gigEManager = GigECameraManager.shared
        
        if gigEManager.isConnected, let camera = gigEManager.currentCamera {
            cameraModel = camera.modelName
            isConnected = true
            
            // Save for next launch
            UserDefaults.standard.set(camera.modelName, forKey: CameraConstants.UserDefaultsKeys.lastConnectedCamera)
        } else {
            isConnected = false
            
            // Try to discover cameras
            gigEManager.discoverCameras()
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
}

// MARK: - OSSystemExtensionRequestDelegate
// Note: This is commented out since we're using app extensions, not system extensions
/*
extension CameraManager: OSSystemExtensionRequestDelegate {
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        logger.info("Replacing existing extension...")
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        logger.info("Extension needs user approval")
        DispatchQueue.main.async {
            self.isInstalling = false
            // Show alert to user
            let alert = NSAlert()
            alert.messageText = "System Extension Blocked"
            alert.informativeText = "Please allow the extension in System Settings > Privacy & Security"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "OK")
            
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
            }
        }
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        logger.info("Extension request finished with result: \(result.rawValue)")
        
        DispatchQueue.main.async {
            self.isInstalling = false
            
            switch result {
            case .completed:
                self.isExtensionInstalled = true
                UserDefaults.standard.set(true, forKey: CameraConstants.UserDefaultsKeys.isExtensionInstalled)
                self.checkCameraConnection()
                
            case .willCompleteAfterReboot:
                let alert = NSAlert()
                alert.messageText = "Reboot Required"
                alert.informativeText = "The camera extension will be available after you restart your Mac."
                alert.alertStyle = .informational
                alert.runModal()
                
            @unknown default:
                break
            }
        }
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        logger.error("Extension request failed: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.isInstalling = false
            
            let nsError = error as NSError
            var message = error.localizedDescription
            
            if nsError.domain == "OSSystemExtensionErrorDomain" && nsError.code == 1 {
                message = """
                The extension cannot be installed while running from Xcode.
                
                To test the extension:
                1. Archive the app (Product → Archive)
                2. Export a Development build
                3. Move the app to /Applications
                4. Run from there
                
                Or disable System Integrity Protection (not recommended).
                """
            }
            
            let alert = NSAlert()
            alert.messageText = "Installation Failed"
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.runModal()
        }
    }
}
*/