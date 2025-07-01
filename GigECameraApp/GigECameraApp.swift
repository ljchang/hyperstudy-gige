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
                .frame(minWidth: 400, idealWidth: 400, maxWidth: 400)
                .onAppear {
                    // Configure window
                    DispatchQueue.main.async {
                        if let window = NSApplication.shared.windows.first {
                            // Set minimum size but allow vertical expansion
                            window.minSize = NSSize(width: 400, height: 500)
                            window.maxSize = NSSize(width: 400, height: CGFloat.greatestFiniteMagnitude)
                            
                            // Make window resizable
                            window.styleMask.insert(.resizable)
                            
                            // Center the window
                            window.center()
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