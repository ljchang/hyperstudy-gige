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

@objc class GigECameraManager: NSObject, ObservableObject {
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
        print("GigECameraManager: Set aravisBridge delegate to self")
        discoverCameras()
    }
    
    // MARK: - Camera Discovery
    
    func discoverCameras() {
        print("GigECameraManager: Starting camera discovery...")
        print("GigECameraManager: Current thread: \(Thread.current)")
        print("GigECameraManager: AravisBridge instance: \(aravisBridge)")
        
        let workItem = DispatchWorkItem(block: { [weak self] in
            print("GigECameraManager: Calling AravisBridge.discoverCameras()...")
            let cameras = AravisBridge.discoverCameras()
            print("GigECameraManager: AravisBridge returned \(cameras.count) cameras")
            
            if cameras.isEmpty {
                print("GigECameraManager: No cameras found. Checking if Aravis is initialized...")
                // Try a direct arv-tool check
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/arv-tool-0.8")
                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = pipe
                
                do {
                    try task.run()
                    task.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        print("GigECameraManager: arv-tool output: \(output)")
                    }
                } catch {
                    print("GigECameraManager: Failed to run arv-tool: \(error)")
                }
            }
            
            for camera in cameras {
                print("  - \(camera.name) at \(camera.ipAddress)")
            }
            
            // Always add a fake camera option
            var allCameras = cameras
            let fakeCamera = AravisCamera(
                deviceId: "aravis-fake-camera",
                name: "Test Camera (Aravis Simulator)",
                modelName: "Aravis Fake GV Camera",
                ipAddress: "127.0.0.1"
            )
            allCameras.append(fakeCamera)
            print("  - \(fakeCamera.name) (Virtual)")
            
            DispatchQueue.main.async {
                self?.availableCameras = allCameras
                
                // Post notification about discovered cameras
                NotificationCenter.default.post(name: NSNotification.Name("GigECamerasDiscovered"), object: nil)
                
                // Auto-connect to first camera if available
                if let firstCamera = cameras.first, self?.currentCamera == nil {
                    print("GigECameraManager: Auto-connecting to \(firstCamera.name)")
                    self?.connect(to: firstCamera)
                }
            }
        })
        
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }
    
    // MARK: - Connection
    
    func connect(to camera: AravisCamera) {
        // Check if this is the fake camera
        if camera.deviceId == "aravis-fake-camera" {
            print("GigECameraManager: Starting fake camera for connection...")
            
            // Start the fake camera
            if AravisBridge.startFakeCamera() {
                // Now discover and connect to the actual fake camera
                let cameras = AravisBridge.discoverCameras()
                if let fakeCamera = cameras.first(where: { $0.modelName.contains("Fake") || $0.deviceId.contains("Fake") }) {
                    print("GigECameraManager: Found running fake camera, connecting...")
                    guard aravisBridge.connect(to: fakeCamera) else {
                        print("GigECameraManager: Failed to connect to fake camera")
                        AravisBridge.stopFakeCamera()
                        return
                    }
                    currentCamera = camera // Keep the UI camera reference
                } else {
                    print("GigECameraManager: Fake camera started but not found in discovery")
                    AravisBridge.stopFakeCamera()
                    return
                }
            } else {
                print("GigECameraManager: Failed to start fake camera")
                return
            }
        } else {
            // Normal camera connection
            guard aravisBridge.connect(to: camera) else {
                return
            }
            currentCamera = camera
        }
    }
    
    func connectToIP(_ ipAddress: String) {
        guard aravisBridge.connectToCamera(atAddress: ipAddress) else {
            return
        }
    }
    
    func disconnect() {
        // Stop fake camera if it was running
        if currentCamera?.deviceId == "aravis-fake-camera" {
            print("GigECameraManager: Stopping fake camera...")
            AravisBridge.stopFakeCamera()
        }
        
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
    @objc func aravisBridge(_ bridge: Any, didReceiveFrame pixelBuffer: CVPixelBuffer) {
        print("GigECameraManager: 🎯 didReceiveFrame called!")
        // Notify all frame handlers
        if frameHandlers.isEmpty {
            print("GigECameraManager: ⚠️ Received frame but no handlers registered!")
        } else {
            // Only log every 30th frame to avoid spam
            frameDistributionCount += 1
            if frameDistributionCount == 1 || frameDistributionCount % 30 == 0 {
                print("GigECameraManager: 📹 Distributing frame #\(frameDistributionCount) to \(frameHandlers.count) handlers")
            }
            for handler in frameHandlers {
                handler(pixelBuffer)
            }
        }
    }
    
    @objc func aravisBridge(_ bridge: Any, didChange state: AravisCameraState) {
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
    
    @objc func aravisBridge(_ bridge: Any, didEncounterError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.lastError = error
            print("Camera error: \(error.localizedDescription)")
        }
    }
}