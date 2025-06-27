#!/usr/bin/env swift

import Foundation
import SystemExtensions
import os.log

class ExtensionManager: NSObject, OSSystemExtensionRequestDelegate {
    private let logger = Logger(subsystem: "com.lukechang.test", category: "extension")
    
    func installExtension() {
        logger.info("Starting extension installation...")
        
        let request = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: "com.lukechang.GigEVirtualCamera.Extension",
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
        
        logger.info("Request submitted")
    }
    
    // MARK: - OSSystemExtensionRequestDelegate
    
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        print("Replacing extension")
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        print("⚠️ Extension needs user approval")
        print("Please allow in System Settings > Privacy & Security")
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        print("✅ Request finished with result: \(result.rawValue)")
        switch result {
        case .completed:
            print("Extension installed successfully!")
        case .willCompleteAfterReboot:
            print("Extension will be available after reboot")
        @unknown default:
            print("Unknown result")
        }
        exit(0)
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        print("❌ Request failed with error: \(error)")
        if let nsError = error as NSError? {
            print("Error code: \(nsError.code)")
            print("Error domain: \(nsError.domain)")
            print("Error info: \(nsError.userInfo)")
        }
        exit(1)
    }
}

// Main
print("Testing system extension installation...")
print("App must be running from /Applications")

let manager = ExtensionManager()
manager.installExtension()

// Keep running
RunLoop.main.run()