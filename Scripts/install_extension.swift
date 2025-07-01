#!/usr/bin/env swift

import Foundation
import SystemExtensions

class ExtensionInstaller: NSObject, OSSystemExtensionRequestDelegate {
    
    func install() {
        print("Installing GigE Virtual Camera Extension...")
        
        let request = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: "com.lukechang.GigEVirtualCamera.Extension",
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
        
        // Keep the script running
        RunLoop.main.run()
    }
    
    // MARK: - OSSystemExtensionRequestDelegate
    
    func request(_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        print("Replacing extension...")
        return .replace
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        print("Extension needs user approval!")
        print("Please go to System Settings > Privacy & Security and allow the extension")
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        switch result {
        case .completed:
            print("Extension installation completed successfully!")
        case .willCompleteAfterReboot:
            print("Extension will complete installation after reboot")
        @unknown default:
            print("Unknown result: \(result)")
        }
        exit(0)
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        print("Extension installation failed: \(error)")
        if let osError = error as? OSSystemExtensionError {
            switch osError.code {
            case .unsupportedParentBundleLocation:
                print("Error: App must be in /Applications folder")
            case .extensionNotFound:
                print("Error: Extension bundle not found")
            case .missingEntitlement:
                print("Error: Missing required entitlement")
            case .authorizationRequired:
                print("Error: Authorization required")
            default:
                print("Error code: \(osError.code.rawValue)")
            }
        }
        exit(1)
    }
}

// Check if running from /Applications
let appPath = Bundle.main.bundlePath
if !appPath.hasPrefix("/Applications/") {
    print("Error: This script must be run from an app in /Applications")
    print("Current path: \(appPath)")
    exit(1)
}

let installer = ExtensionInstaller()
installer.install()