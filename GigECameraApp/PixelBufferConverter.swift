//
//  PixelBufferConverter.swift
//  GigECameraApp
//
//  Converts pixel buffers between formats
//

import Foundation
import CoreVideo
import VideoToolbox
import os.log

class PixelBufferConverter {
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera", category: "PixelBufferConverter")
    private var converter: VTPixelTransferSession?
    
    init() {
        // Create pixel transfer session
        VTPixelTransferSessionCreate(allocator: kCFAllocatorDefault, pixelTransferSessionOut: &converter)
        
        if let converter = converter {
            // Set conversion quality
            VTSessionSetProperty(converter, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Normal)
        }
    }
    
    deinit {
        converter = nil
    }
    
    /// Convert BGRA to YUV420 (420v) format for video streaming
    func convertBGRAToYUV420(_ bgraBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let converter = converter else {
            logger.error("No pixel transfer session available")
            return nil
        }
        
        let width = CVPixelBufferGetWidth(bgraBuffer)
        let height = CVPixelBufferGetHeight(bgraBuffer)
        
        // Create YUV420 output buffer
        let pixelBufferAttributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
        ]
        
        var yuvBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            pixelBufferAttributes as CFDictionary,
            &yuvBuffer
        )
        
        guard status == kCVReturnSuccess, let outputBuffer = yuvBuffer else {
            logger.error("Failed to create YUV buffer: \(status)")
            return nil
        }
        
        // Perform the conversion
        let transferResult = VTPixelTransferSessionTransferImage(
            converter,
            from: bgraBuffer,
            to: outputBuffer
        )
        
        if transferResult != noErr {
            logger.error("Failed to convert pixel buffer: \(transferResult)")
            return nil
        }
        
        return outputBuffer
    }
    
    /// Convert to standard HD resolution if needed
    func convertToHD(_ inputBuffer: CVPixelBuffer, targetWidth: Int = 1280, targetHeight: Int = 720) -> CVPixelBuffer? {
        let currentWidth = CVPixelBufferGetWidth(inputBuffer)
        let currentHeight = CVPixelBufferGetHeight(inputBuffer)
        
        // If already HD, just convert format
        if currentWidth == targetWidth && currentHeight == targetHeight {
            return convertBGRAToYUV420(inputBuffer)
        }
        
        // Need to scale and convert
        guard let converter = converter else {
            logger.error("No pixel transfer session available")
            return nil
        }
        
        // Create scaled YUV buffer
        let pixelBufferAttributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelBufferWidthKey: targetWidth,
            kCVPixelBufferHeightKey: targetHeight,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
        ]
        
        var scaledBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            targetWidth,
            targetHeight,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            pixelBufferAttributes as CFDictionary,
            &scaledBuffer
        )
        
        guard status == kCVReturnSuccess, let outputBuffer = scaledBuffer else {
            logger.error("Failed to create scaled buffer: \(status)")
            return nil
        }
        
        // Perform scaling and format conversion
        let transferResult = VTPixelTransferSessionTransferImage(
            converter,
            from: inputBuffer,
            to: outputBuffer
        )
        
        if transferResult != noErr {
            logger.error("Failed to scale and convert pixel buffer: \(transferResult)")
            return nil
        }
        
        return outputBuffer
    }
}