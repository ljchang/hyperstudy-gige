//
//  XPCFrameSender.swift
//  GigEVirtualCamera
//
//  Sends frames to the camera extension via XPC
//

import Foundation
import CoreVideo
import os.log

class XPCFrameSender: NSObject {
    
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera", category: "XPCFrameSender")
    private var xpcConnection: NSXPCConnection?
    private let serviceName = "group.S368GH6KF7.com.lukechang.GigEVirtualCamera.Extension"
    
    override init() {
        super.init()
        setupXPCConnection()
    }
    
    private func setupXPCConnection() {
        logger.info("Setting up XPC connection to extension")
        
        // Create XPC connection to the extension's Mach service
        xpcConnection = NSXPCConnection(machServiceName: serviceName, options: [])
        
        // Set up the interface - we'll define a simple protocol
        xpcConnection?.remoteObjectInterface = NSXPCInterface(with: CameraExtensionXPCProtocol.self)
        
        xpcConnection?.interruptionHandler = { [weak self] in
            self?.logger.warning("XPC connection interrupted")
        }
        
        xpcConnection?.invalidationHandler = { [weak self] in
            self?.logger.warning("XPC connection invalidated")
            self?.xpcConnection = nil
        }
        
        xpcConnection?.resume()
        logger.info("XPC connection resumed")
    }
    
    func sendFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let connection = xpcConnection else {
            logger.error("No XPC connection available")
            return
        }
        
        // For now, let's just test the connection
        // In a real implementation, we'd send the pixel buffer data or IOSurface reference
        logger.debug("Would send frame via XPC")
    }
    
    func testConnection() {
        guard let connection = xpcConnection else {
            logger.error("No XPC connection for test")
            return
        }
        
        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            self.logger.error("XPC test failed: \(error.localizedDescription)")
        }
        
        // Cast to protocol and call a test method
        if let extensionProxy = proxy as? CameraExtensionXPCProtocol {
            extensionProxy.ping { response in
                self.logger.info("XPC ping response: \(response)")
            }
        }
    }
}

// Define the XPC protocol
@objc protocol CameraExtensionXPCProtocol {
    func ping(reply: @escaping (String) -> Void)
    func sendFrameData(_ data: Data, width: Int, height: Int)
}