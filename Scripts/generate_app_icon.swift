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
    
    // Grey background matching the app's theme
    NSColor(calibratedWhite: 0.85, alpha: 1.0).setFill()
    path.fill()
    
    // Green color matching the status green in the app
    let greenColor = NSColor(red: 50/255.0, green: 215/255.0, blue: 75/255.0, alpha: 1.0)
    
    // Draw camera body
    let cameraWidth = actualSize.width * 0.5
    let cameraHeight = actualSize.height * 0.35
    let cameraX = (actualSize.width - cameraWidth) / 2
    let cameraY = (actualSize.height - cameraHeight) / 2
    
    // Camera body
    let cameraRect = NSRect(x: cameraX, y: cameraY, width: cameraWidth, height: cameraHeight)
    let cameraPath = NSBezierPath(roundedRect: cameraRect, xRadius: cameraWidth * 0.1, yRadius: cameraWidth * 0.1)
    greenColor.setFill()
    cameraPath.fill()
    
    // Camera lens (circle in center)
    let lensSize = cameraHeight * 0.7
    let lensRect = NSRect(
        x: cameraX + (cameraWidth - lensSize) / 2,
        y: cameraY + (cameraHeight - lensSize) / 2,
        width: lensSize,
        height: lensSize
    )
    let lensPath = NSBezierPath(ovalIn: lensRect)
    // Use the same grey as the background
    NSColor(calibratedWhite: 0.85, alpha: 1.0).setFill()
    lensPath.fill()
    
    // Inner lens circle
    let innerLensSize = lensSize * 0.7
    let innerLensRect = NSRect(
        x: lensRect.minX + (lensSize - innerLensSize) / 2,
        y: lensRect.minY + (lensSize - innerLensSize) / 2,
        width: innerLensSize,
        height: innerLensSize
    )
    let innerLensPath = NSBezierPath(ovalIn: innerLensRect)
    greenColor.withAlphaComponent(0.8).setFill()
    innerLensPath.fill()
    
    // Camera viewfinder on top
    let viewfinderWidth = cameraWidth * 0.25
    let viewfinderHeight = cameraHeight * 0.2
    let viewfinderRect = NSRect(
        x: cameraX + (cameraWidth - viewfinderWidth) / 2,
        y: cameraY + cameraHeight - viewfinderHeight * 0.3,
        width: viewfinderWidth,
        height: viewfinderHeight
    )
    let viewfinderPath = NSBezierPath(roundedRect: viewfinderRect, xRadius: viewfinderWidth * 0.2, yRadius: viewfinderWidth * 0.2)
    greenColor.setFill()
    viewfinderPath.fill()
    
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

let assetsPath = "/Users/lukechang/Github/hyperstudy-gige/GigECameraApp/Assets.xcassets/AppIcon.appiconset"

for (baseSize, scale) in sizes {
    let actualSize = baseSize * scale
    if let icon = createAppIcon(size: CGSize(width: baseSize, height: baseSize), scale: CGFloat(scale)) {
        let filename = scale == 1 ? "icon_\(baseSize)x\(baseSize).png" : "icon_\(baseSize)x\(baseSize)@\(scale)x.png"
        let path = "\(assetsPath)/\(filename)"
        saveImage(icon, to: path)
    }
}

print("App icon generation complete!")