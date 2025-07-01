#!/usr/bin/env swift

import AppKit
import CoreGraphics

// Icon sizes needed for macOS app
let iconSizes: [(size: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

// Design parameters
let backgroundColor = NSColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0) // Dark grey
let iconColor = NSColor.white // Pure white for high contrast
let cornerRadiusRatio = 0.2 // 20% of icon size for rounded corners

// Output directory
let outputDir = "../GigECameraApp/Assets.xcassets/AppIcon.appiconset"

// Create output directory if needed
let fileManager = FileManager.default
let outputPath = NSString(string: outputDir).expandingTildeInPath
try? fileManager.createDirectory(atPath: outputPath, withIntermediateDirectories: true, attributes: nil)

// Generate each icon size
for (baseSize, scale) in iconSizes {
    let actualSize = baseSize * scale
    let filename = scale == 1 ? "icon_\(baseSize)x\(baseSize).png" : "icon_\(baseSize)x\(baseSize)@\(scale)x.png"
    
    // Create image
    let image = NSImage(size: NSSize(width: actualSize, height: actualSize))
    
    image.lockFocus()
    
    // Create rounded rectangle path
    let rect = NSRect(x: 0, y: 0, width: actualSize, height: actualSize)
    let cornerRadius = CGFloat(actualSize) * cornerRadiusRatio
    let roundedPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Clip to rounded rectangle
    roundedPath.addClip()
    
    // Fill background with dark grey
    backgroundColor.setFill()
    rect.fill()
    
    // Configure and draw camera icon
    let iconConfig = NSImage.SymbolConfiguration(pointSize: Double(actualSize) * 0.5, weight: .medium)
    if let cameraIcon = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(iconConfig) {
        
        // Create a white version of the icon
        let whiteIcon = NSImage(size: cameraIcon.size)
        whiteIcon.lockFocus()
        
        // Draw the camera icon
        cameraIcon.draw(in: NSRect(origin: .zero, size: cameraIcon.size))
        
        // Apply white color on top using sourceIn to colorize
        iconColor.setFill()
        NSRect(origin: .zero, size: cameraIcon.size).fill(using: .sourceIn)
        
        whiteIcon.unlockFocus()
        
        // Center the icon
        let x = (CGFloat(actualSize) - cameraIcon.size.width) / 2
        let y = (CGFloat(actualSize) - cameraIcon.size.height) / 2
        
        whiteIcon.draw(at: NSPoint(x: x, y: y), 
                      from: NSRect(origin: .zero, size: cameraIcon.size),
                      operation: .sourceOver,
                      fraction: 1.0)
    }
    
    image.unlockFocus()
    
    // Save as PNG
    if let tiffData = image.tiffRepresentation,
       let bitmapRep = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapRep.representation(using: .png, properties: [:]) {
        
        let filePath = "\(outputPath)/\(filename)"
        try? pngData.write(to: URL(fileURLWithPath: filePath))
        print("Generated: \(filename)")
    }
}

// Update Contents.json
let contentsJson = """
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

let contentsPath = "\(outputPath)/Contents.json"
try? contentsJson.write(to: URL(fileURLWithPath: contentsPath), atomically: true, encoding: .utf8)

print("✅ App icons generated successfully!")
print("📁 Icons saved to: \(outputPath)")