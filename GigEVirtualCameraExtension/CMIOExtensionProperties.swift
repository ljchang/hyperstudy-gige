//
//  CMIOExtensionProperties.swift
//  GigEVirtualCameraExtension
//
//  Custom CMIO properties for IOSurface coordination
//

import Foundation
import CoreMediaIO
import IOSurface

// Define custom properties for IOSurface coordination
extension CMIOExtensionProperty {
    static let currentIOSurfaceID = CMIOExtensionProperty(
        rawValue: "com.lukechang.gigevirtualcamera.iosurface-id"
    )
    static let frameTimestamp = CMIOExtensionProperty(
        rawValue: "com.lukechang.gigevirtualcamera.frame-timestamp"
    )
    static let frameIndex = CMIOExtensionProperty(
        rawValue: "com.lukechang.gigevirtualcamera.frame-index"
    )
}

// Protocol for IOSurface frame updates
protocol IOSurfaceFrameReceiver: AnyObject {
    func didReceiveNewIOSurface(_ surfaceID: IOSurfaceID, timestamp: CMTime, frameIndex: Int)
}