//
//  IOSurfaceFrameSharing.swift
//  GigEVirtualCamera
//
//  Handles IOSurface-based frame sharing between app and extension
//

import Foundation
import CoreVideo
import IOSurface
import QuartzCore
import os.log

// MARK: - XPC Protocol

@objc protocol FrameSharingXPCProtocol {
    func receiveFrame(surfaceID: IOSurfaceID, timestamp: Double)
    func ping(reply: @escaping (String) -> Void)
}

// MARK: - Frame Sender (App Side)

class IOSurfaceFrameSender: NSObject {
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera", category: "IOSurfaceFrameSender")
    private var xpcConnection: NSXPCConnection?
    private let serviceName = "group.S368GH6KF7.com.lukechang.GigEVirtualCamera"
    private var frameCount: UInt64 = 0
    
    override init() {
        super.init()
        setupXPCConnection()
    }
    
    private func setupXPCConnection() {
        logger.info("Setting up XPC connection to extension with service name: \(self.serviceName)")
        
        xpcConnection = NSXPCConnection(machServiceName: serviceName, options: [])
        guard let connection = xpcConnection else {
            logger.error("Failed to create NSXPCConnection")
            return
        }
        
        connection.remoteObjectInterface = NSXPCInterface(with: FrameSharingXPCProtocol.self)
        
        connection.interruptionHandler = { [weak self] in
            self?.logger.warning("XPC connection interrupted")
        }
        
        connection.invalidationHandler = { [weak self] in
            self?.logger.warning("XPC connection invalidated")
            self?.xpcConnection = nil
            // Try to reconnect after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self?.setupXPCConnection()
            }
        }
        
        connection.resume()
        logger.info("XPC connection resumed, testing connection...")
        
        // Test the connection immediately
        testConnection { [weak self] connected in
            if connected {
                self?.logger.info("XPC connection test successful!")
            } else {
                self?.logger.error("XPC connection test failed - extension may not be listening")
            }
        }
    }
    
    func sendFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let connection = xpcConnection else {
            if frameCount % 30 == 0 {
                logger.error("No XPC connection available")
            }
            return
        }
        
        // Get or create IOSurface from pixel buffer
        guard let surface = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
            if frameCount % 30 == 0 {
                logger.error("Failed to get IOSurface from pixel buffer - buffer may not be IOSurface-backed")
            }
            return
        }
        
        let surfaceID = IOSurfaceGetID(surface)
        let timestamp = CACurrentMediaTime()
        
        if frameCount == 0 {
            logger.info("Sending first frame with surface ID: \(surfaceID)")
        }
        
        let proxy = connection.remoteObjectProxyWithErrorHandler { [weak self] error in
            if self?.frameCount ?? 0 % 30 == 0 {
                self?.logger.error("Failed to send frame: \(error.localizedDescription)")
            }
        }
        
        if let extensionProxy = proxy as? FrameSharingXPCProtocol {
            extensionProxy.receiveFrame(surfaceID: surfaceID, timestamp: timestamp)
            
            frameCount += 1
            if frameCount % 30 == 0 {
                logger.info("Sent frame \(self.frameCount) with surface ID: \(surfaceID)")
            }
        } else {
            logger.error("Failed to get extension proxy")
        }
    }
    
    func testConnection(completion: @escaping (Bool) -> Void) {
        guard let connection = xpcConnection else {
            completion(false)
            return
        }
        
        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            self.logger.error("XPC test failed: \(error.localizedDescription)")
            completion(false)
        }
        
        if let extensionProxy = proxy as? FrameSharingXPCProtocol {
            extensionProxy.ping { response in
                self.logger.info("XPC ping response: \(response)")
                completion(true)
            }
        }
    }
}

// MARK: - Frame Receiver (Extension Side)

class IOSurfaceFrameReceiver: NSObject {
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "IOSurfaceFrameReceiver")
    private var frameHandler: ((CVPixelBuffer) -> Void)?
    
    func setFrameHandler(_ handler: @escaping (CVPixelBuffer) -> Void) {
        frameHandler = handler
    }
    
    func receiveFrame(surfaceID: IOSurfaceID, timestamp: Double) {
        // Look up the IOSurface by ID
        guard let surface = IOSurfaceLookup(surfaceID) else {
            logger.error("Failed to lookup IOSurface with ID: \(surfaceID)")
            return
        }
        
        // Create pixel buffer from IOSurface
        var pixelBuffer: Unmanaged<CVPixelBuffer>?
        let attributes: CFDictionary? = nil
        let result = CVPixelBufferCreateWithIOSurface(
            kCFAllocatorDefault,
            surface,
            attributes,
            &pixelBuffer
        )
        
        guard result == kCVReturnSuccess, let unmanagedBuffer = pixelBuffer else {
            logger.error("Failed to create pixel buffer from IOSurface: \(result)")
            return
        }
        
        let buffer = unmanagedBuffer.takeRetainedValue()
        
        // Send to handler
        frameHandler?(buffer)
        
        logger.debug("Received frame with surface ID: \(surfaceID), timestamp: \(timestamp)")
    }
}

// MARK: - XPC Service Handler (Extension Side)

class FrameSharingXPCService: NSObject, FrameSharingXPCProtocol, NSXPCListenerDelegate {
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "XPCService")
    private let frameReceiver = IOSurfaceFrameReceiver()
    private var listener: NSXPCListener?
    
    func start(frameHandler: @escaping (CVPixelBuffer) -> Void) {
        frameReceiver.setFrameHandler(frameHandler)
        
        let serviceName = "group.S368GH6KF7.com.lukechang.GigEVirtualCamera"
        logger.info("Starting XPC listener with service name: \(serviceName)")
        
        // Create XPC listener with the Mach service name
        listener = NSXPCListener(machServiceName: serviceName)
        guard let listener = listener else {
            logger.error("Failed to create NSXPCListener")
            return
        }
        
        listener.delegate = self
        listener.resume()
        
        logger.info("XPC service started and listening on: \(serviceName)")
    }
    
    // MARK: - NSXPCListenerDelegate
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        logger.info("New XPC connection request from PID: \(newConnection.processIdentifier)")
        
        newConnection.exportedInterface = NSXPCInterface(with: FrameSharingXPCProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.interruptionHandler = {
            self.logger.warning("Client connection interrupted")
        }
        
        newConnection.invalidationHandler = {
            self.logger.info("Client connection invalidated")
        }
        
        newConnection.resume()
        logger.info("XPC connection accepted and resumed")
        return true
    }
    
    // MARK: - FrameSharingXPCProtocol
    
    func receiveFrame(surfaceID: IOSurfaceID, timestamp: Double) {
        frameReceiver.receiveFrame(surfaceID: surfaceID, timestamp: timestamp)
    }
    
    func ping(reply: @escaping (String) -> Void) {
        logger.info("Received ping")
        reply("Pong from extension at \(Date())")
    }
}