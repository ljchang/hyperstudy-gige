# Producer-Consumer Model Fix for IOSurface Frame Flow

## Correct Architecture

The CMIO Camera Extension should follow a producer-consumer model:

1. **App (Producer)**: 
   - Connects to camera and immediately starts streaming
   - Continuously writes frames to IOSurface shared memory
   - Doesn't need to know about clients

2. **Extension (Consumer)**:
   - When client (Photo Booth) connects, starts reading from shared memory
   - Sends frames to client at requested rate
   - Multiple clients can consume the same stream

## Changes Made

### 1. Auto-Start Streaming on Connection

The app now automatically starts streaming when it connects to a camera:

```swift
// In connectToCamera()
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    if gigEManager.isConnected && !gigEManager.isStreaming {
        self.logger.info("Auto-starting streaming after connection (producer model)...")
        gigEManager.startStreaming()
    }
}
```

### 2. Handle State Changes

Added auto-start on state change notifications:

```swift
// In handleGigECameraStateChange()
if gigEManager.isConnected && !gigEManager.isStreaming {
    self.logger.info("Auto-starting streaming on state change (producer model)...")
    gigEManager.startStreaming()
}
```

### 3. Removed Inter-Process Notifications

The extension no longer needs to notify the app about client connections. It simply:
- Starts its timer when client connects
- Reads from shared memory
- Stops timer when client disconnects

## Benefits

1. **Lower Latency**: Frames are always ready when clients connect
2. **Simpler Architecture**: No coordination needed between app and extension
3. **Multiple Clients**: Can serve multiple clients without app changes
4. **More Reliable**: No race conditions or timing issues

## Testing

1. Launch the app
2. Select test camera from dropdown
3. App should automatically start streaming (check logs for "Starting acquisition")
4. Open Photo Booth and select "GigE Virtual Camera"
5. Frames should appear immediately

## Monitoring

```bash
# Watch for auto-start
log stream --predicate 'eventMessage contains "Auto-starting streaming"' --info

# Check frame flow
log stream --predicate 'eventMessage contains "Wrote frame" OR eventMessage contains "Cached frame"' --info
```