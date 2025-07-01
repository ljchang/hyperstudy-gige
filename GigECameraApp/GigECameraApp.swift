//
//  GigECameraApp.swift
//  GigEVirtualCamera
//
//  Created on 6/24/25.
//

import SwiftUI

@main
struct GigECameraApp: App {
    @StateObject private var cameraManager = CameraManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cameraManager)
                .frame(width: 400, height: cameraManager.isShowingPreview ? 720 : 440)
                .animation(.easeInOut(duration: 0.3), value: cameraManager.isShowingPreview)
                .onAppear {
                    // Configure window
                    DispatchQueue.main.async {
                        if let window = NSApplication.shared.windows.first {
                            window.setContentSize(NSSize(width: 400, height: 440))
                            window.minSize = NSSize(width: 400, height: 440)
                            window.maxSize = NSSize(width: 600, height: 800)
                            window.styleMask.insert(.resizable)
                            window.center()
                        }
                    }
                }
                .onChange(of: cameraManager.isShowingPreview) { newValue in
                    // Animate window resize when preview toggles
                    DispatchQueue.main.async {
                        if let window = NSApplication.shared.windows.first {
                            let newHeight: CGFloat = newValue ? 720 : 440
                            let currentFrame = window.frame
                            let newFrame = NSRect(
                                x: currentFrame.origin.x,
                                y: currentFrame.origin.y + currentFrame.height - newHeight,
                                width: 400,
                                height: newHeight
                            )
                            window.setFrame(newFrame, display: true, animate: true)
                        }
                    }
                }
        }
        
        // Menu bar commands
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About GigE Virtual Camera") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        NSApplication.AboutPanelOptionKey.applicationName: "GigE Virtual Camera",
                        NSApplication.AboutPanelOptionKey.applicationVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
                        NSApplication.AboutPanelOptionKey.version: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1",
                        NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2025 Luke Chang"
                    ])
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy
        NSApp.setActivationPolicy(.regular)
        
        // Bring to front
        NSApp.activate(ignoringOtherApps: true)
        
        // Extension installation is now handled manually via UI buttons
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up preview if open
        CameraManager.shared.hidePreview()
    }
}