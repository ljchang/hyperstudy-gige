# Extension Not Streaming - Diagnosis

## Current State
1. ✅ App is writing frames to IOSurface 379 at 25 fps
2. ✅ Frame index is incrementing properly (using lowercase `currentFrameIndex`)
3. ✅ Single IOSurface simplification is working
4. ✅ Extension process is running
5. ❌ Extension is NOT reading frames or sending to Photo Booth

## Root Cause
The extension's `startStream()` method is never being called. We can see CMIO connection/disconnection events but no stream start.

## Possible Issues

### 1. Logger Not Working
The extension uses `Logger` but we see no logs. System extensions might need different logging:
```swift
// Current (not working):
private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera.Extension", category: "StreamSource")

// Alternative: Use NSLog or os_log
NSLog("Stream started!")
```

### 2. Photo Booth Not Starting Stream
Photo Booth connects to the extension but may not be calling `startStream()`. This could be due to:
- Format negotiation failing
- Authorization failing
- Stream properties missing

### 3. Extension Not Visible Properly
The extension shows in system but might not be properly advertising its capabilities.

## Next Steps

### Option 1: Add Debug File Logging
Since Logger isn't working, write to a file:
```swift
func debugLog(_ message: String) {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("extension_debug.log")
    let timestamp = Date().description
    let log = "\(timestamp): \(message)\n"
    try? log.append(to: url)
}
```

### Option 2: Use NSLog Instead
Replace all `logger.info()` with `NSLog()` which should appear in Console.app

### Option 3: Test with Different App
Try QuickTime Player or OBS instead of Photo Booth to see if it's app-specific.

## The Good News
- Frame flow infrastructure is working correctly
- IOSurface sharing is functioning
- The simplified single-buffer approach eliminates sync issues

We just need to figure out why the extension isn't starting its stream!