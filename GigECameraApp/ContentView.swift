//
//  ContentView.swift
//  GigEVirtualCamera
//
//  Created on 6/24/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @State private var previewImage: NSImage?
    @StateObject private var extensionManager = ExtensionManager.shared
    
    var body: some View {
        ZStack {
            // Background
            VisualEffectBackground()
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Header with camera icon
                HeaderView(isConnected: cameraManager.isConnected)
                    .padding(.top, DesignSystem.Spacing.large)
                
                // Extension Status and Controls
                VStack(spacing: DesignSystem.Spacing.medium) {
                    HStack {
                        Text("Camera Extension Status:")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text(extensionManager.extensionStatus)
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(extensionManager.extensionStatus == "Installed" ? .green : DesignSystem.Colors.textSecondary)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        Button(action: {
                            extensionManager.installExtension()
                        }) {
                            Label("Install Extension", systemImage: "plus.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(extensionManager.isInstalling || extensionManager.extensionStatus == "Installed")
                        
                        Button(action: {
                            extensionManager.uninstallExtension()
                        }) {
                            Label("Uninstall Extension", systemImage: "minus.circle")
                        }
                        .buttonStyle(.bordered)
                        .disabled(extensionManager.isInstalling || extensionManager.extensionStatus != "Installed")
                    }
                    
                    if extensionManager.extensionStatus == "Needs Approval" {
                        HStack(spacing: DesignSystem.Spacing.small) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Please approve in System Settings > Privacy & Security")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Debug button to reconnect frame sender
                    if extensionManager.extensionStatus == "Installed" && !cameraManager.isFrameSenderConnected {
                        Button(action: {
                            cameraManager.retryFrameSenderConnection()
                        }) {
                            Label("Connect to Virtual Camera", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Test XPC button
                    if extensionManager.extensionStatus == "Installed" {
                        Button(action: {
                            cameraManager.testXPCConnection()
                        }) {
                            Label("Test XPC Connection", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Debug feedback area
                    if !extensionManager.statusMessage.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Debug Output:")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Text(extensionManager.statusMessage)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if !extensionManager.errorDetail.isEmpty {
                                Text("Error Detail: \(extensionManager.errorDetail)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(DesignSystem.Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.05))
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
                .padding(.horizontal, DesignSystem.Spacing.large)
                
                Divider()
                    .padding(.horizontal, DesignSystem.Spacing.large)
                
                // Camera selection section
                if !cameraManager.availableCameras.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.small) {
                        HStack {
                            Image(systemName: "camera.on.rectangle")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Text("Select Camera")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Spacer()
                        }
                        
                        Picker("", selection: $cameraManager.selectedCameraId) {
                            Text("None").tag(nil as String?)
                            ForEach(cameraManager.availableCameras, id: \.deviceId) { camera in
                                Text("\(camera.name) (\(camera.ipAddress))")
                                    .tag(camera.deviceId as String?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                }
                
                // Status section
                VStack(spacing: DesignSystem.Spacing.medium) {
                    StatusRow(
                        icon: "circle.fill",
                        title: "Status",
                        value: cameraManager.statusText,
                        valueColor: cameraManager.statusColor
                    )
                    
                    if cameraManager.isConnected {
                        StatusRow(
                            icon: "camera.fill",
                            title: "Camera",
                            value: cameraManager.cameraModel
                        )
                        
                        StatusRow(
                            icon: "video.fill",
                            title: "Format",
                            value: cameraManager.currentFormat
                        )
                        
                        // Pixel format selector
                        HStack {
                            Label("Pixel Format", systemImage: "square.grid.3x3.fill")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Picker("", selection: $cameraManager.currentPixelFormat) {
                                ForEach(cameraManager.availablePixelFormats, id: \.self) { format in
                                    Text(format).tag(format)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 120)
                        }
                        
                        // Preview toggle button
                        Button(action: {
                            cameraManager.togglePreview()
                            
                            // Animate window resize
                            DispatchQueue.main.async {
                                if let window = NSApplication.shared.windows.first {
                                    NSAnimationContext.runAnimationGroup({ context in
                                        context.duration = 0.3
                                        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                                        
                                        let targetHeight: CGFloat = cameraManager.isShowingPreview ? 800 : 500
                                        var frame = window.frame
                                        let heightDiff = targetHeight - frame.height
                                        frame.size.height = targetHeight
                                        frame.origin.y -= heightDiff // Keep window top edge in place
                                        
                                        window.animator().setFrame(frame, display: true)
                                    })
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: cameraManager.isShowingPreview ? "eye.slash.fill" : "eye.fill")
                                Text(cameraManager.isShowingPreview ? "Hide Preview" : "Show Preview")
                            }
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                            .padding(.vertical, DesignSystem.Spacing.small)
                            .background(DesignSystem.Colors.statusGreen)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, DesignSystem.Spacing.small)
                        
                        // Embedded preview
                        if cameraManager.isShowingPreview {
                            CameraPreviewSection(previewImage: $previewImage)
                                .environmentObject(cameraManager)
                                .frame(height: 300)
                                .padding(.top, DesignSystem.Spacing.medium)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .scale)
                                ))
                                .animation(.easeInOut(duration: 0.3), value: cameraManager.isShowingPreview)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                
                Spacer(minLength: DesignSystem.Spacing.small)
            }
            .padding(.bottom, DesignSystem.Spacing.small)
        }
        .frame(minHeight: cameraManager.isShowingPreview ? 800 : 500)
        .animation(.easeInOut(duration: 0.3), value: cameraManager.isShowingPreview)
    }
}

// MARK: - Header View

struct HeaderView: View {
    let isConnected: Bool
    @State private var iconRotation: Double = 0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            // Animated camera icon
            Image(systemName: isConnected ? "camera.fill" : "camera")
                .font(.system(size: 48))
                .foregroundColor(isConnected ? DesignSystem.Colors.statusGreen : DesignSystem.Colors.textSecondary)
                .rotationEffect(.degrees(iconRotation))
                .animation(DesignSystem.Animation.spring, value: iconRotation)
                .onAppear {
                    if isConnected {
                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            iconRotation = 5
                        }
                    }
                }
            
            Text("GigE Virtual Camera")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

// MARK: - Status Row

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = DesignSystem.Colors.textPrimary
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}


// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .hudWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Camera Preview Section

struct CameraPreviewSection: View {
    @Binding var previewImage: NSImage?
    @EnvironmentObject var cameraManager: CameraManager
    @StateObject private var frameHandler = PreviewFrameHandler()
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(Color.black)
            
            if let image = frameHandler.currentImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 280)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            } else {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Text("Waiting for camera feed...")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.white)
                        .padding(.top, DesignSystem.Spacing.small)
                }
            }
        }
        .frame(height: 300)
        .onAppear {
            print("CameraPreviewSection: ===== VIEW APPEARED =====")
            hasAppeared = true
            // Delay to ensure view is stable
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                frameHandler.startReceivingFrames()
            }
        }
        .onDisappear {
            print("CameraPreviewSection: ===== VIEW DISAPPEARED =====")
            hasAppeared = false
            frameHandler.stopReceivingFrames()
        }
    }
}

// MARK: - Preview Frame Handler

class PreviewFrameHandler: ObservableObject {
    @Published var currentImage: NSImage?
    private let gigEManager = GigECameraManager.shared
    private var frameCount = 0
    
    
    func startReceivingFrames() {
        print("PreviewFrameHandler: Starting to receive frames")
        
        // Check if camera is connected first
        guard gigEManager.isConnected else {
            print("PreviewFrameHandler: Camera not connected, cannot start preview")
            return
        }
        
        // Start streaming if not already
        if !gigEManager.isStreaming {
            print("PreviewFrameHandler: Starting streaming...")
            gigEManager.startStreaming()
            
            // Give it a moment to start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.setupFrameHandler()
            }
        } else {
            print("PreviewFrameHandler: Already streaming")
            setupFrameHandler()
        }
    }
    
    private func setupFrameHandler() {
        print("PreviewFrameHandler: Setting up frame handler")
        
        // Add frame handler with simpler conversion
        gigEManager.addFrameHandler { [weak self] pixelBuffer in
            guard let self = self else { return }
            
            self.frameCount += 1
            
            // Only log every 30th frame
            if self.frameCount % 30 == 1 {
                print("PreviewFrameHandler: Got frame #\(self.frameCount)")
            }
            
            // Simple CIImage to NSImage conversion
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let rep = NSCIImageRep(ciImage: ciImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            
            // Update on main thread
            DispatchQueue.main.async {
                self.currentImage = nsImage
                if self.frameCount % 30 == 1 {
                    print("PreviewFrameHandler: Updated UI with frame #\(self.frameCount)")
                }
            }
        }
        
        print("PreviewFrameHandler: Frame handler added")
    }
    
    func stopReceivingFrames() {
        print("PreviewFrameHandler: Stopping frame reception after \(frameCount) frames")
        gigEManager.stopStreaming()
        gigEManager.removeAllFrameHandlers()
        frameCount = 0
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CameraManager.shared)
            .frame(width: 400)
    }
}