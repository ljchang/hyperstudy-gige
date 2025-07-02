# Frame Flow Coordination Fix

## Problem

The current implementation has a coordination issue:
1. Photo Booth connects to the virtual camera and requests streaming
2. The extension starts its timer to send frames at 30fps
3. BUT the app doesn't know to start capturing from the GigE camera
4. Result: Extension tries to send frames but there are none to send

## Solution

The extension needs to notify the app when clients start/stop streaming. This maintains the CMIO model where clients control streaming.

### 1. Add Distributed Notification from Extension

In `GigEVirtualCameraExtensionStreamSource.swift`:

```swift
func startStream() throws {
    // ... existing code ...
    
    // Notify the app that streaming should start
    DistributedNotificationCenter.default().post(
        name: NSNotification.Name("com.lukechang.GigEVirtualCamera.StartStreaming"),
        object: nil
    )
    
    logger.info("Posted start streaming notification to app")
}

func stopStream() throws {
    // ... existing code ...
    
    // Notify the app that streaming should stop
    DistributedNotificationCenter.default().post(
        name: NSNotification.Name("com.lukechang.GigEVirtualCamera.StopStreaming"),
        object: nil
    )
    
    logger.info("Posted stop streaming notification to app")
}
```

### 2. Handle Notifications in App

In `CameraManager.swift`:

```swift
private func setupNotifications() {
    // ... existing notifications ...
    
    // Listen for streaming control from extension
    DistributedNotificationCenter.default().addObserver(
        self,
        selector: #selector(handleStartStreamingRequest),
        name: NSNotification.Name("com.lukechang.GigEVirtualCamera.StartStreaming"),
        object: nil
    )
    
    DistributedNotificationCenter.default().addObserver(
        self,
        selector: #selector(handleStopStreamingRequest),
        name: NSNotification.Name("com.lukechang.GigEVirtualCamera.StopStreaming"),
        object: nil
    )
}

@objc private func handleStartStreamingRequest() {
    logger.info("Received start streaming request from extension")
    
    if isConnected && !GigECameraManager.shared.isStreaming {
        logger.info("Starting camera streaming...")
        GigECameraManager.shared.startStreaming()
    }
}

@objc private func handleStopStreamingRequest() {
    logger.info("Received stop streaming request from extension")
    
    if GigECameraManager.shared.isStreaming {
        logger.info("Stopping camera streaming...")
        GigECameraManager.shared.stopStreaming()
    }
}
```

## Alternative: Polling Approach

If distributed notifications have timing issues, use shared UserDefaults:

```swift
// Extension writes:
sharedDefaults?.set(true, forKey: "clientRequestingFrames")

// App polls:
Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
    let shouldStream = sharedDefaults?.bool(forKey: "clientRequestingFrames") ?? false
    // Start/stop streaming based on this flag
}
```

## Testing

1. Launch the app and connect to test camera (but don't start streaming)
2. Open Photo Booth and select "GigE Virtual Camera"
3. The extension should notify the app to start streaming
4. Frames should flow: Camera → App → IOSurface → Extension → Photo Booth