//
//  IOSurfaceFrameWriter.swift
//  GigECameraApp
//
//  Discovers extension's IOSurfaces via CMIO properties and writes frames
//

import Foundation
import CoreVideo
import IOSurface
import CoreMediaIO
import os.log

// MARK: - Frame Coordinator for App

class FrameCoordinator {
    static let shared = FrameCoordinator()
    
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera", category: "FrameCoordinator")
    private let appGroupID = "group.S368GH6KF7.com.lukechang.GigEVirtualCamera"
    private let surfaceIDsKey = "IOSurfaceIDs"
    private let frameIndexKey = "currentFrameIndex"
    
    private var groupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    func readSurfaceIDs() -> [IOSurfaceID]? {
        guard let defaults = groupDefaults else {
            logger.error("Failed to access App Group UserDefaults")
            return nil
        }
        
        guard let idArray = defaults.array(forKey: surfaceIDsKey) as? [NSNumber] else {
            return nil
        }
        
        let surfaceIDs = idArray.map { IOSurfaceID($0.uint32Value) }
        logger.info("Read \(surfaceIDs.count) IOSurface IDs from App Groups: \(surfaceIDs)")
        return surfaceIDs
    }
    
    func markFrameReady(index: Int) {
        guard let defaults = groupDefaults else { return }
        defaults.set(index, forKey: frameIndexKey)
        defaults.synchronize()
    }
}

class IOSurfaceFrameWriter {
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera", category: "IOSurfaceFrameWriter")
    
    // Extension's surface IDs discovered via App Groups
    private var surfaceIDs: [IOSurfaceID] = []
    private var currentIndex = 0
    private let lock = NSLock()
    
    // Frame tracking
    private var frameIndex: Int = 0
    private let frameCoordinator = FrameCoordinator.shared
    
    init() {
        // Discover surface IDs from extension via App Groups
        discoverSurfaceIDs()
        logger.info("✅ IOSurfaceFrameWriter initialized")
    }
    
    private func discoverSurfaceIDs() {
        // Try to read IOSurface IDs immediately
        if let ids = frameCoordinator.readSurfaceIDs() {
            lock.lock()
            surfaceIDs = ids
            lock.unlock()
            logger.info("Discovered \(ids.count) IOSurface IDs from extension: \(ids)")
        } else {
            logger.info("No IOSurface IDs available yet, will retry on first frame write")
        }
    }
    
    func writeFrame(_ sourcePixelBuffer: CVPixelBuffer) {
        lock.lock()
        defer { lock.unlock() }
        
        // Try to discover IDs again if we don't have them
        if surfaceIDs.isEmpty {
            if let ids = frameCoordinator.readSurfaceIDs() {
                surfaceIDs = ids
                logger.info("Late discovery: Found \(ids.count) IOSurface IDs from extension: \(ids)")
            }
        }
        
        guard !surfaceIDs.isEmpty else {
            // If we still don't have surface IDs, log warning
            if frameIndex % 30 == 0 {
                logger.warning("No IOSurface IDs discovered yet. Extension may not be running.")
            }
            frameIndex += 1
            return
        }
        
        // Get the current surface ID
        let surfaceID = surfaceIDs[currentIndex]
        
        // Look up the IOSurface
        guard let ioSurface = IOSurfaceLookup(surfaceID) else {
            logger.error("Failed to lookup IOSurface with ID: \(surfaceID)")
            return
        }
        
        // Copy frame data to the IOSurface
        copyPixelBufferToIOSurface(from: sourcePixelBuffer, to: ioSurface)
        
        frameIndex += 1
        // Simplified: always use index 0 (single buffer)
        currentIndex = 0
        
        // Notify extension that a new frame is ready
        frameCoordinator.markFrameReady(index: frameIndex)
        
        // Log every 30th frame
        if frameIndex % 30 == 1 {
            let width = CVPixelBufferGetWidth(sourcePixelBuffer)
            let height = CVPixelBufferGetHeight(sourcePixelBuffer)
            logger.info("📤 Wrote frame #\(self.frameIndex) to IOSurface: \(surfaceID) | \(width)x\(height)")
        }
    }
    
    private func copyPixelBufferToIOSurface(from pixelBuffer: CVPixelBuffer, to ioSurface: IOSurface) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        IOSurfaceLock(ioSurface, [], nil)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            IOSurfaceUnlock(ioSurface, [], nil)
        }
        
        guard let srcBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            logger.error("Failed to get source base address")
            return
        }
        
        let dstBaseAddress = IOSurfaceGetBaseAddress(ioSurface)
        
        let srcWidth = CVPixelBufferGetWidth(pixelBuffer)
        let srcHeight = CVPixelBufferGetHeight(pixelBuffer)
        let srcBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let dstWidth = IOSurfaceGetWidth(ioSurface)
        let dstHeight = IOSurfaceGetHeight(ioSurface)
        let dstBytesPerRow = IOSurfaceGetBytesPerRow(ioSurface)
        
        // Copy what fits
        let copyWidth = min(srcWidth, dstWidth)
        let copyHeight = min(srcHeight, dstHeight)
        
        // Copy row by row
        for y in 0..<copyHeight {
            let srcRow = srcBaseAddress.advanced(by: y * srcBytesPerRow)
            let dstRow = dstBaseAddress.advanced(by: y * dstBytesPerRow)
            memcpy(dstRow, srcRow, copyWidth * 4) // 4 bytes per pixel for BGRA
        }
    }
    
    func reset() {
        frameIndex = 0
        currentIndex = 0
        logger.info("Frame writer reset")
    }
    
    // Helper to manually set surface IDs for testing
    func setSurfaceIDs(_ ids: [IOSurfaceID]) {
        lock.lock()
        defer { lock.unlock() }
        
        surfaceIDs = ids
        logger.info("Manually set IOSurface IDs: \(ids)")
    }
}