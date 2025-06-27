//
//  CameraPreviewView.swift
//  GigEVirtualCamera
//
//  Camera preview window
//

import SwiftUI
import CoreVideo

struct CameraPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    @StateObject private var frameHandler = FrameHandler()
    
    var body: some View {
        ZStack {
            // Camera feed
            if let image = frameHandler.currentImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Placeholder when no feed
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Waiting for camera feed...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    )
            }
            
            // Overlay with camera info
            VStack {
                HStack {
                    Text(cameraManager.cameraModel)
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text("FPS: \(frameHandler.fps, specifier: "%.1f")")
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .padding()
                
                Spacer()
            }
        }
        .frame(minWidth: 320, minHeight: 240)
        .onAppear {
            frameHandler.startReceivingFrames()
        }
        .onDisappear {
            frameHandler.stopReceivingFrames()
        }
    }
}

// MARK: - Frame Handler
class FrameHandler: ObservableObject {
    @Published var currentImage: NSImage?
    @Published var fps: Double = 0.0
    
    private var frameCount = 0
    private var lastFPSUpdate = Date()
    private let gigEManager = GigECameraManager.shared
    
    func startReceivingFrames() {
        // Add frame handler to GigECameraManager
        gigEManager.addFrameHandler { [weak self] pixelBuffer in
            self?.handleFrame(pixelBuffer)
        }
    }
    
    func stopReceivingFrames() {
        gigEManager.removeAllFrameHandlers()
    }
    
    private func handleFrame(_ pixelBuffer: CVPixelBuffer) {
        // Update FPS
        frameCount += 1
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFPSUpdate)
        if elapsed > 1.0 {
            DispatchQueue.main.async {
                self.fps = Double(self.frameCount) / elapsed
            }
            frameCount = 0
            lastFPSUpdate = now
        }
        
        // Convert CVPixelBuffer to NSImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            
            DispatchQueue.main.async {
                self.currentImage = nsImage
            }
        }
    }
}