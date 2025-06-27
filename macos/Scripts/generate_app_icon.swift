#!/usr/bin/swift

import AppKit
import CoreGraphics

// Function to create app icon
func createAppIcon(size: CGSize, scale: CGFloat = 1.0) -> NSImage? {
    let actualSize = CGSize(width: size.width * scale, height: size.height * scale)
    
    let image = NSImage(size: actualSize)
    image.lockFocus()
    
    // Draw grey background with rounded corners
    let rect = NSRect(origin: .zero, size: actualSize)
    let cornerRadius = actualSize.width * 0.18
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Grey background similar to system preference panes
    NSColor(calibratedWhite: 0.95, alpha: 1.0).setFill()
    path.fill()
    
    // Draw green camera icon
    let iconSize = actualSize.width * 0.6
    let iconRect = NSRect(
        x: (actualSize.width - iconSize) / 2,
        y: (actualSize.height - iconSize) / 2,
        width: iconSize,
        height: iconSize
    )
    
    // Green color matching the status green in the app
    let greenColor = NSColor(red: 50/255.0, green: 215/255.0, blue: 75/255.0, alpha: 1.0)
    
    // Create the camera symbol
    let config = NSImage.SymbolConfiguration(pointSize: iconSize * 0.7, weight: .medium, scale: .large)
    if let cameraImage = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: nil) {
        let tintedImage = cameraImage.withSymbolConfiguration(config)
        tintedImage?.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        // Apply green tint
        greenColor.set()
        iconRect.fill(using: .sourceAtop)
    }
    
    image.unlockFocus()
    
    return image
}

// Function to save image as PNG
func saveImage(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved icon: \(path)")
    } catch {
        print("Failed to save icon: \(error)")
    }
}

// Generate all required icon sizes
let sizes: [(size: Int, scale: Int)] = [
    (16, 1), (16, 2),    // 16pt @1x and @2x
    (32, 1), (32, 2),    // 32pt @1x and @2x
    (128, 1), (128, 2),  // 128pt @1x and @2x
    (256, 1), (256, 2),  // 256pt @1x and @2x
    (512, 1), (512, 2)   // 512pt @1x and @2x
]

let assetsPath = "/Users/lukechang/Github/hyperstudy-gige/macos/GigECameraApp/Assets.xcassets/AppIcon.appiconset"

for (baseSize, scale) in sizes {
    let actualSize = baseSize * scale
    if let icon = createAppIcon(size: CGSize(width: baseSize, height: baseSize), scale: CGFloat(scale)) {
        let filename = scale == 1 ? "icon_\(baseSize)x\(baseSize).png" : "icon_\(baseSize)x\(baseSize)@\(scale)x.png"
        let path = "\(assetsPath)/\(filename)"
        saveImage(icon, to: path)
    }
}

print("App icon generation complete!")