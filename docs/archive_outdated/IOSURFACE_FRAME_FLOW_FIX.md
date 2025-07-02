# IOSurface Frame Flow Fix

## Problem Analysis

The current implementation has several issues preventing frames from flowing correctly:

1. **Missing Streaming Start**: The app connects to the camera but doesn't automatically start streaming
2. **No Frame Generation**: The fake camera is created but frames aren't being captured/processed
3. **UserDefaults Timing**: Potential synchronization delays between app and extension

## Required Fixes

### 1. Auto-start Streaming After Connection

In `CameraManager.swift`, modify the connection flow to automatically start streaming:

```swift
private func connectToCamera(withId cameraId: String) {
    let gigEManager = GigECameraManager.shared
    
    if let camera = availableCameras.first(where: { $0.deviceId == cameraId }) {
        gigEManager.connect(to: camera)
        
        // Auto-start streaming after successful connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if gigEManager.isConnected && !gigEManager.isStreaming {
                self.logger.info("Auto-starting streaming after connection...")
                gigEManager.startStreaming()
            }
        }
    }
}
```

### 2. Ensure Aravis Frame Callback is Working

The Aravis bridge needs to ensure frames are being generated from the fake camera. Check that:
- The stream callback is properly registered
- Buffers are being acquired and processed
- The delegate is being called with frames

### 3. Add Frame Flow Diagnostics

Add more logging to track frame flow:

```swift
// In IOSurfaceFrameWriter.writeFrame()
logger.info("📤 Writing frame #\(self.frameIndex) | IOSurface: \(surfaceID) | \(width)x\(height)")

// In IOSurfaceFrameCache.getCurrentPixelBuffer()  
logger.info("📥 Reading frame #\(frameIndex) | IOSurface: \(surfaceID)")

// In StreamSource.sendNextFrame()
logger.info("📤 Sending frame #\(self.frameCount) via CMIO")
```

### 4. Test Pattern Generation

As a fallback, ensure test pattern generation works:

```swift
// In CameraManager, add a test pattern timer
private func startTestPatternGeneration() {
    Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
        guard let testBuffer = PixelBufferHelpers.createIOSurfaceBackedPixelBuffer(
            width: 640, height: 480, pixelFormat: kCVPixelFormatType_32BGRA
        ) else { return }
        
        // Fill with test pattern
        self.fillTestPattern(testBuffer)
        self.frameWriter.writeFrame(testBuffer)
    }
}
```

### 5. Verify IOSurface Persistence

Ensure IOSurfaces remain valid across process boundaries:

```swift
// Use kIOSurfaceIsGlobal property when creating IOSurface
let ioSurfaceProps = [
    kIOSurfaceIsGlobal as String: true,
    kIOSurfaceCacheMode as String: kIOMapDefaultCache
]
```

## Quick Test Steps

1. Kill any existing processes:
   ```bash
   pkill GigEVirtualCamera
   pkill GigECameraExtension
   ```

2. Clear shared defaults:
   ```bash
   defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera
   ```

3. Launch the app and verify:
   - Camera connects
   - Streaming starts automatically
   - Frames are being written (check logs)

4. Open Photo Booth:
   - Select "GigE Virtual Camera"
   - Verify frames appear

## Monitoring Commands

```bash
# Watch frame flow
log stream --predicate 'eventMessage contains "Frame #"' --info

# Check shared defaults
watch -n 1 'defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera'

# Monitor IOSurface creation
sudo dtrace -n 'IOSurface*:entry { printf("%s\n", probefunc); }'
```