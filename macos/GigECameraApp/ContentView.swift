//
//  ContentView.swift
//  GigEVirtualCamera
//
//  Created on 6/24/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @State private var isHoveringInstall = false
    
    var body: some View {
        ZStack {
            // Background
            VisualEffectBackground()
            
            VStack(spacing: DesignSystem.Spacing.large) {
                // Header with camera icon
                HeaderView(isConnected: cameraManager.isConnected)
                    .padding(.top, DesignSystem.Spacing.xLarge)
                
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
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xLarge)
                
                Divider()
                    .padding(.horizontal, DesignSystem.Spacing.xLarge)
                
                // Extension control
                ExtensionControlSection(
                    isInstalled: cameraManager.isExtensionInstalled,
                    isInstalling: cameraManager.isInstalling,
                    onInstall: {
                        Task {
                            #if DEBUG
                            // Check if running from Xcode
                            if Bundle.main.bundlePath.contains("DerivedData") {
                                // Show alert about test mode
                                let alert = NSAlert()
                                alert.messageText = "Running in Test Mode"
                                alert.informativeText = "System extensions cannot be installed when running from Xcode.\n\nSimulating successful installation for UI testing."
                                alert.addButton(withTitle: "OK")
                                alert.runModal()
                                
                                // Simulate installation
                                cameraManager.isExtensionInstalled = true
                                cameraManager.isConnected = true
                                cameraManager.cameraModel = "MRC MR-CAM-HR (Test Mode)"
                            } else {
                                await cameraManager.installExtension()
                            }
                            #else
                            await cameraManager.installExtension()
                            #endif
                        }
                    },
                    onUninstall: {
                        Task {
                            await cameraManager.uninstallExtension()
                        }
                    }
                )
                .padding(.horizontal, DesignSystem.Spacing.xLarge)
                
                Spacer()
                
                // Compatibility info
                CompatibilityInfoView()
                    .padding(.horizontal, DesignSystem.Spacing.xLarge)
                    .padding(.bottom, DesignSystem.Spacing.large)
            }
        }
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

// MARK: - Extension Control Section

struct ExtensionControlSection: View {
    let isInstalled: Bool
    let isInstalling: Bool
    let onInstall: () -> Void
    let onUninstall: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            if isInstalled {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.statusGreen)
                    Text("Extension Installed")
                        .font(DesignSystem.Typography.callout)
                }
                
                Button(action: onUninstall) {
                    Text("Uninstall Extension")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            } else {
                Button(action: onInstall) {
                    HStack {
                        if isInstalling {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle")
                        }
                        Text(isInstalling ? "Installing..." : "Install Extension")
                    }
                    .font(DesignSystem.Typography.headline)
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.vertical, DesignSystem.Spacing.small)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isInstalling)
                .scaleEffect(isHovering ? 1.05 : 1.0)
                .onHover { hovering in
                    withAnimation(DesignSystem.Animation.fast) {
                        isHovering = hovering
                    }
                }
            }
        }
    }
}

// MARK: - Compatibility Info View

struct CompatibilityInfoView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xSmall) {
            Text("Compatible with:")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: DesignSystem.Spacing.small) {
                ForEach(["Zoom", "Teams", "OBS", "QuickTime"], id: \.self) { app in
                    Text(app)
                        .font(DesignSystem.Typography.footnote)
                        .padding(.horizontal, DesignSystem.Spacing.xSmall)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
            }
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

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(Color.accentColor)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CameraManager.shared)
            .frame(width: 400, height: 500)
    }
}