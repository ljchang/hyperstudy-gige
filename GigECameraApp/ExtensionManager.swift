//
//  ExtensionManager.swift
//  GigEVirtualCamera
//
//  Manages the installation and activation of the Camera Extension
//

import Foundation
import SystemExtensions
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
