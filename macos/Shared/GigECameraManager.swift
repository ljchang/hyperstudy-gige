//
//  GigECameraManager.swift
//  GigEVirtualCamera
//
//  Swift wrapper for Aravis bridge
//

import Foundation
import CoreVideo
import Combine

// Using stub implementation for now
// When Aravis is properly integrated, remove the stub

class GigECameraManager: NSObject, ObservableObject {
    static let shared = GigECameraManager()
    
    @Published var isConnected = false
    @Published var isStreaming = false
    @Published var availableCameras: [AravisCamera] = []
    @Published var currentCamera: AravisCamera?
    @Published var frameRate: Double = 30.0
    @Published var lastError: Error?
    
    private let aravisBridge = AravisBridge()
    private var frameHandlers: [(CVPixelBuffer) -> Void] = []
    
    override init() {
        super.init()
        aravisBridge.delegate = self
        discoverCameras()
    }
    
    // MARK: - Camera Discovery
    
    func discoverCameras() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let cameras = AravisBridge.discoverCameras()
            DispatchQueue.main.async {
                self?.availableCameras = cameras
                
                // Auto-connect to first camera if available
                if let firstCamera = cameras.first, self?.currentCamera == nil {
                    self?.connect(to: firstCamera)
                }
            }
        }
    }
    
    // MARK: - Connection
    
    func connect(to camera: AravisCamera) {
        guard aravisBridge.connect(to: camera) else {
            return
        }
        currentCamera = camera
    }
    
    func connectToIP(_ ipAddress: String) {
        guard aravisBridge.connectToCamera(atAddress: ipAddress) else {
            return
        }
    }
    
    func disconnect() {
        aravisBridge.disconnect()
        currentCamera = nil
    }
    
    // MARK: - Streaming
    
    func startStreaming() {
        guard aravisBridge.startStreaming() else {
            return
        }
    }
    
    func stopStreaming() {
        aravisBridge.stopStreaming()
    }
    
    // MARK: - Frame Handling
    
    func addFrameHandler(_ handler: @escaping (CVPixelBuffer) -> Void) {
        frameHandlers.append(handler)
    }
    
    func removeAllFrameHandlers() {
        frameHandlers.removeAll()
    }
    
    // MARK: - Camera Settings
    
    func setFrameRate(_ fps: Double) {
        if aravisBridge.setFrameRate(fps) {
            frameRate = fps
        }
    }
    
    func setExposureTime(_ microseconds: Double) {
        _ = aravisBridge.setExposureTime(microseconds)
    }
    
    func setGain(_ gain: Double) {
        _ = aravisBridge.setGain(gain)
    }
}

// MARK: - AravisBridgeDelegate

extension GigECameraManager: AravisBridgeDelegate {
    func aravisBridge(_ bridge: Any, didReceiveFrame pixelBuffer: CVPixelBuffer) {
        // Notify all frame handlers
        for handler in frameHandlers {
            handler(pixelBuffer)
        }
    }
    
    func aravisBridge(_ bridge: Any, didChange state: AravisCameraState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .disconnected:
                self?.isConnected = false
                self?.isStreaming = false
            case .connected:
                self?.isConnected = true
                self?.isStreaming = false
            case .streaming:
                self?.isConnected = true
                self?.isStreaming = true
            case .error:
                self?.isConnected = false
                self?.isStreaming = false
            default:
                break
            }
        }
    }
    
    func aravisBridge(_ bridge: Any, didEncounterError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.lastError = error
            print("Camera error: \(error.localizedDescription)")
        }
    }
}