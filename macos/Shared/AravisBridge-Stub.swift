//
//  AravisBridge-Stub.swift
//  GigEVirtualCamera
//
//  Stub implementation for building without Aravis library
//

import Foundation
import CoreVideo

@objc public enum AravisCameraState: Int {
    case disconnected = 0
    case connecting
    case connected
    case streaming
    case error
}

@objc public protocol AravisBridgeDelegate: AnyObject {
    func aravisBridge(_ bridge: Any, didReceiveFrame pixelBuffer: CVPixelBuffer)
    func aravisBridge(_ bridge: Any, didChange state: AravisCameraState)
    func aravisBridge(_ bridge: Any, didEncounterError error: Error)
}

@objc public class AravisCamera: NSObject {
    @objc public let name: String
    @objc public let modelName: String
    @objc public let deviceId: String
    @objc public let ipAddress: String
    
    init(name: String, modelName: String, deviceId: String, ipAddress: String) {
        self.name = name
        self.modelName = modelName
        self.deviceId = deviceId
        self.ipAddress = ipAddress
        super.init()
    }
}

@objc public class AravisBridge: NSObject {
    @objc public weak var delegate: AravisBridgeDelegate?
    @objc public private(set) var state: AravisCameraState = .disconnected
    @objc public private(set) var currentCamera: AravisCamera?
    
    @objc public static func discoverCameras() -> [AravisCamera] {
        // Return test camera for now
        return [AravisCamera(
            name: "MRC Systems MR-CAM-HR",
            modelName: "MR-CAM-HR",
            deviceId: "test-device",
            ipAddress: "169.254.90.244"
        )]
    }
    
    @objc public func connectToCamera(_ camera: AravisCamera) -> Bool {
        state = .connecting
        delegate?.aravisBridge(self, didChange: state)
        
        // Simulate connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.currentCamera = camera
            self.state = .connected
            self.delegate?.aravisBridge(self, didChange: self.state)
        }
        return true
    }
    
    @objc public func connectToCameraWithIP(_ ipAddress: String) -> Bool {
        let camera = AravisCamera(
            name: "GigE Camera",
            modelName: "Unknown",
            deviceId: "ip-device",
            ipAddress: ipAddress
        )
        return connectToCamera(camera)
    }
    
    @objc public func disconnect() {
        stopStreaming()
        currentCamera = nil
        state = .disconnected
        delegate?.aravisBridge(self, didChange: state)
    }
    
    @objc public func startStreaming() -> Bool {
        guard state == .connected else { return false }
        state = .streaming
        delegate?.aravisBridge(self, didChange: state)
        
        // Simulate frame generation
        generateTestFrames()
        return true
    }
    
    @objc public func stopStreaming() {
        if state == .streaming {
            state = .connected
            delegate?.aravisBridge(self, didChange: state)
        }
    }
    
    @objc public func setFrameRate(_ frameRate: Double) -> Bool { return true }
    @objc public func setExposureTime(_ exposureTimeUs: Double) -> Bool { return true }
    @objc public func setGain(_ gain: Double) -> Bool { return true }
    
    @objc public func frameRate() -> Double { return 30.0 }
    @objc public func exposureTime() -> Double { return 1000.0 }
    @objc public func gain() -> Double { return 1.0 }
    
    private func generateTestFrames() {
        guard state == .streaming else { return }
        
        // Create test frame
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            1920, 1080,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        
        if let buffer = pixelBuffer {
            delegate?.aravisBridge(self, didReceiveFrame: buffer)
        }
        
        // Continue generating frames
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.033) { [weak self] in
            self?.generateTestFrames()
        }
    }
}