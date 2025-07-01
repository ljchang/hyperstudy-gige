//
//  ExtensionManager.swift
//  GigEVirtualCamera
//
//  Manages the installation and activation of the Camera Extension
//

import Foundation
import SystemExtensions
import CoreMediaIO
import os.log

class ExtensionManager: NSObject, ObservableObject {
    static let shared = ExtensionManager()
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera", category: "ExtensionManager")
    
    @Published var extensionStatus: String = "Not Installed"
    @Published var isInstalling = false
    @Published var statusMessage: String = ""
    @Published var errorDetail: String = ""
    
    override init() {
        super.init()
        checkExtensionStatus()
    }
    
    func installExtension() {
        guard !isInstalling else { return }
        
        isInstalling = true
        extensionStatus = "Installing..."
        statusMessage = "Submitting installation request..."
        errorDetail = ""
        logger.info("Starting extension installation")
        
        let request = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: "com.lukechang.GigEVirtualCamera.Extension",
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
    }
    
    func uninstallExtension() {
        isInstalling = true
        extensionStatus = "Uninstalling..."
        statusMessage = "Submitting deactivation request..."
        errorDetail = ""
        
        let request = OSSystemExtensionRequest.deactivationRequest(
            forExtensionWithIdentifier: "com.lukechang.GigEVirtualCamera.Extension",
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
    }
    
    func checkExtensionStatus() {
        // Check if extension is already installed by trying to find it in the system
        statusMessage = "Checking extension status..."
        
        // Use systemextensionsctl output or check if the virtual camera exists
        DispatchQueue.global(qos: .background).async { [weak self] in
            let task = Process()
            task.launchPath = "/usr/bin/systemextensionsctl"
            task.arguments = ["list"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        if output.contains("com.lukechang.GigEVirtualCamera.Extension") {
                            if output.contains("[activated enabled]") {
                                self?.extensionStatus = "Installed"
                                self?.statusMessage = "Extension is installed and active"
                                self?.logger.info("Extension is already installed")
                                // Trigger the extension to start
                                self?.triggerExtensionStart()
                            } else if output.contains("[terminated waiting") {
                                self?.extensionStatus = "Pending Uninstall"
                                self?.statusMessage = "Extension waiting to uninstall"
                            } else {
                                self?.extensionStatus = "Not Active"
                                self?.statusMessage = "Extension found but not active"
                            }
                        } else {
                            self?.extensionStatus = "Not Installed"
                            self?.statusMessage = "Extension not found in system"
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.logger.error("Failed to check extension status: \(error.localizedDescription)")
                    self?.statusMessage = "Could not determine extension status"
                }
            }
        }
    }
    
    private func triggerExtensionStart() {
        logger.info("Triggering extension start by enumerating CMIO devices")
        
        // Enable virtual camera discovery
        var prop = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var allow: UInt32 = 1
        CMIOObjectSetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &prop,
            0,
            nil,
            UInt32(MemoryLayout<UInt32>.size),
            &allow
        )
        
        // Enumerate CMIO devices to trigger extension loading
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        CMIOObjectGetPropertyDataSize(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        logger.info("CMIO device enumeration triggered - extension should start now")
    }
}

extension ExtensionManager: OSSystemExtensionRequestDelegate {
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        let message = "Replacing extension version \(existing.bundleShortVersion) with \(ext.bundleShortVersion)"
        logger.info("\(message)")
        statusMessage = "🔄 actionForReplacingExtension: \(message)"
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        logger.info("Extension needs user approval")
        extensionStatus = "Needs Approval"
        statusMessage = "⚠️ requestNeedsUserApproval: Extension needs user approval"
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        isInstalling = false
        switch result {
        case .completed:
            logger.info("Extension installation completed")
            extensionStatus = "Installed"
            statusMessage = "✅ didFinishWithResult: completed"
        case .willCompleteAfterReboot:
            logger.info("Extension will complete after reboot")
            extensionStatus = "Reboot Required"
            statusMessage = "🔄 didFinishWithResult: willCompleteAfterReboot"
        @unknown default:
            logger.error("Unknown installation result")
            extensionStatus = "Unknown Status"
            statusMessage = "❓ didFinishWithResult: unknown result"
        }
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        isInstalling = false
        logger.error("Extension installation failed: \(error.localizedDescription)")
        extensionStatus = "Installation Failed"
        
        var errorMessage = "❌ didFailWithError: \(error.localizedDescription)"
        
        if let osError = error as? OSSystemExtensionError {
            switch osError.code {
            case .missingEntitlement:
                logger.error("Missing entitlement for system extension")
                errorDetail = "Missing entitlement for system extension"
            case .unsupportedParentBundleLocation:
                logger.error("App must be in /Applications folder")
                errorDetail = "App must be in /Applications folder"
            case .extensionNotFound:
                logger.error("Extension bundle not found")
                errorDetail = "Extension bundle not found"
            case .unknownExtensionCategory:
                logger.error("Unknown extension category")
                errorDetail = "Unknown extension category"
            case .codeSignatureInvalid:
                logger.error("Invalid code signature")
                errorDetail = "Invalid code signature"
            case .validationFailed:
                logger.error("Validation failed")
                errorDetail = "Validation failed"
            case .forbiddenBySystemPolicy:
                logger.error("Forbidden by system policy")
                errorDetail = "Forbidden by system policy"
            case .requestCanceled:
                logger.error("Request canceled")
                errorDetail = "Request canceled"
            case .requestSuperseded:
                logger.error("Request superseded")
                errorDetail = "Request superseded"
            case .authorizationRequired:
                logger.error("Authorization required")
                errorDetail = "Authorization required"
            @unknown default:
                logger.error("Unknown error code: \(osError.code.rawValue)")
                errorDetail = "Unknown error code: \(osError.code.rawValue)"
            }
            errorMessage = "❌ didFailWithError: \(errorDetail)"
        }
        
        statusMessage = errorMessage
    }
    
    func request(_ request: OSSystemExtensionRequest, foundProperties properties: [OSSystemExtensionProperties]) {
        logger.info("Found \(properties.count) extension(s)")
        var message = "🔍 foundProperties: Found \(properties.count) extension(s)"
        for property in properties {
            logger.info("Extension version: \(property.bundleShortVersion)")
            message += "\n  - Version: \(property.bundleShortVersion)"
        }
        statusMessage = message
    }
}
