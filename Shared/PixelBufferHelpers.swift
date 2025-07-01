//
//  PixelBufferHelpers.swift
//  GigEVirtualCamera
//
//  Helper functions for creating IOSurface-backed pixel buffers
//

import Foundation
import CoreVideo
import IOSurface

class PixelBufferHelpers {
    
    static func createIOSurfaceBackedPixelBuffer(width: Int, height: Int, pixelFormat: OSType = kCVPixelFormatType_32BGRA) -> CVPixelBuffer? {
        // Create IOSurface directly with proper properties for cross-process sharing
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let allocSize = height * bytesPerRow
        
        let surfaceProps: [String: Any] = [
            kIOSurfaceWidth as String: width,
            kIOSurfaceHeight as String: height,
            kIOSurfaceBytesPerRow as String: bytesPerRow,
            kIOSurfaceBytesPerElement as String: bytesPerPixel,
            kIOSurfaceAllocSize as String: allocSize,
            kIOSurfacePixelFormat as String: pixelFormat
        ]
        
        guard let surface = IOSurfaceCreate(surfaceProps as CFDictionary) else {
            return nil
        }
        
        // Create pixel buffer from IOSurface
        var pixelBuffer: Unmanaged<CVPixelBuffer>?
        let result = CVPixelBufferCreateWithIOSurface(
            kCFAllocatorDefault,
            surface,
            nil,
            &pixelBuffer
        )
        
        guard result == kCVReturnSuccess, let unmanagedBuffer = pixelBuffer else {
            return nil
        }
        
        return unmanagedBuffer.takeRetainedValue()
    }
    
    static func createIOSurfaceBackedPixelBufferOld(width: Int, height: Int, pixelFormat: OSType = kCVPixelFormatType_32BGRA) -> CVPixelBuffer? {
        // IOSurface properties - empty dictionary
        let ioSurfaceProperties: [String: Any] = [:]
        
        // Pixel buffer attributes
        let attributes: [String: Any] = [
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
            kCVPixelBufferIOSurfacePropertiesKey as String: ioSurfaceProperties,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let result = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        return result == kCVReturnSuccess ? pixelBuffer : nil
    }
    
    static func ensureIOSurfaceBacking(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        // Check if already has IOSurface
        if CVPixelBufferGetIOSurface(pixelBuffer) != nil {
            return pixelBuffer
        }
        
        // Create new IOSurface-backed pixel buffer and copy data
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        guard let newPixelBuffer = createIOSurfaceBackedPixelBuffer(
            width: width,
            height: height,
            pixelFormat: pixelFormat
        ) else {
            return nil
        }
        
        // Copy pixel data
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(newPixelBuffer, [])
        
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(newPixelBuffer, [])
        }
        
        let srcData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let dstData = CVPixelBufferGetBaseAddress(newPixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let dataSize = bytesPerRow * height
        
        if let src = srcData, let dst = dstData {
            memcpy(dst, src, dataSize)
        }
        
        return newPixelBuffer
    }
}