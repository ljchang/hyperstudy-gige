//
//  CameraConstants.swift
//  GigEVirtualCamera
//
//  Created on 6/24/25.
//

import Foundation

struct CameraConstants {
    // MARK: - Bundle Identifiers
    struct BundleID {
        static let app = "com.lukechang.GigEVirtualCamera"
        static let appGroup = "group.com.lukechang.gigecamera"
        static let cameraExtension = "com.lukechang.GigEVirtualCamera.Extension"
    }
    
    // MARK: - Camera Info
    struct Camera {
        static let name = "GigE Virtual Camera"
        static let manufacturer = "Luke Chang"
        static let defaultWidth = 1920
        static let defaultHeight = 1080
        static let defaultFrameRate = 30
    }
    
    // MARK: - Supported Formats
    struct Formats {
        static let format1080p30 = VideoFormat(width: 1920, height: 1080, frameRate: 30)
        static let format720p60 = VideoFormat(width: 1280, height: 720, frameRate: 60)
        static let format720p30 = VideoFormat(width: 1280, height: 720, frameRate: 30)
        static let format480p30 = VideoFormat(width: 640, height: 480, frameRate: 30)
        
        static let all = [format1080p30, format720p60, format720p30, format480p30]
    }
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let isExtensionInstalled = "isExtensionInstalled"
        static let lastConnectedCamera = "lastConnectedCamera"
        static let selectedFormatIndex = "selectedFormatIndex"
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let cameraDidConnect = Notification.Name("GigECameraDidConnect")
        static let cameraDidDisconnect = Notification.Name("GigECameraDidDisconnect")
        static let extensionStatusChanged = Notification.Name("ExtensionStatusChanged")
    }
}

// MARK: - Video Format Model

struct VideoFormat: Equatable, Codable {
    let width: Int
    let height: Int
    let frameRate: Int
    
    var displayName: String {
        "\(width)×\(height) @ \(frameRate)fps"
    }
    
    var shortName: String {
        switch (width, height) {
        case (1920, 1080): return "1080p"
        case (1280, 720): return "720p"
        case (640, 480): return "480p"
        default: return "\(height)p"
        }
    }
}