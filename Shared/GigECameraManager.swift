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
    @Published var preferredPixelFormat: String = "Auto"
    
    private let aravisBridge = AravisBridge()
    private var frameHandlers: [(CVPixelBuffer) -> Void] = []
    private var lastDiscoveryTime = Date.distantPast
    private var connectionRetryCount = 0
    private var frameDistributionCount = 0
    
    override init() {
        super.init()
        aravisBridge.delegate = self
        discoverCameras()
    }
    
    // MARK: - Camera Discovery
    
    func discoverCameras() {
        print("GigECameraManager: Starting camera discovery...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let cameras = AravisBridge.discoverCameras()
            print("GigECameraManager: Found \(cameras.count) cameras")
            for camera in cameras {
                print("  - \(camera.name) at \(camera.ipAddress)")
            }
            DispatchQueue.main.async {
                self?.availableCameras = cameras
                
                // Post notification about discovered cameras
                NotificationCenter.default.post(name: NSNotification.Name("GigECamerasDiscovered"), object: nil)
                
                // Auto-connect to first camera if available
                if let firstCamera = cameras.first, self?.currentCamera == nil {
                    print("GigECameraManager: Auto-connecting to \(firstCamera.name)")
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
        print("GigECameraManager: startStreaming called, isConnected=\(isConnected)")
        guard isConnected else {
            print("GigECameraManager: Cannot start streaming - not connected")
            return
        }
        
        guard aravisBridge.startStreaming() else {
            print("GigECameraManager: aravisBridge.startStreaming() failed")
            return
        }
        print("GigECameraManager: Streaming started successfully")
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
    
    func setPixelFormat(_ format: String) {
        preferredPixelFormat = format
        // Notify the bridge about format preference
        aravisBridge.setPreferredPixelFormat(format)
    }
}

// MARK: - AravisBridgeDelegate

extension GigECameraManager: AravisBridgeDelegate {
    func aravisBridge(_ bridge: Any, didReceiveFrame pixelBuffer: CVPixelBuffer) {
        // Notify all frame handlers
        if frameHandlers.isEmpty {
            print("GigECameraManager: Received frame but no handlers registered")
        } else {
            // Only log every 30th frame to avoid spam
            frameDistributionCount += 1
            if frameDistributionCount % 30 == 1 {
                print("GigECameraManager: Distributing frame #\(frameDistributionCount) to \(frameHandlers.count) handlers")
            }
            for handler in frameHandlers {
                handler(pixelBuffer)
            }
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
            
            // Post state change notification
            NotificationCenter.default.post(name: NSNotification.Name("GigECameraStateChanged"), object: nil)
        }
    }
    
    func aravisBridge(_ bridge: Any, didEncounterError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.lastError = error
            print("Camera error: \(error.localizedDescription)")
        }
    }
}