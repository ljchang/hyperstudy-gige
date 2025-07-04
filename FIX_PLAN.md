# Fix Plan for Sink-to-Source Bridge

## Current Issue
- Frames are arriving at the sink but not reaching Photo Booth
- The DeviceSource bridge requires `streamingCounter > 0` to forward frames
- But `streamingCounter` only increments after Photo Booth fully connects
- This creates a deadlock where Photo Booth won't connect without seeing frames

## Root Cause
The conditional check `if self.streamingCounter > 0` in the bridge is too restrictive. Photo Booth needs to see frames to complete its connection process.

## Solution Options

### Option 1: Always Forward When Sink is Active (Recommended)
Change the bridge logic to:
```swift
// Always forward frames when sink is active, regardless of source clients
if self.isSinking {
    self.sourceStreamSource.sendSampleBuffer(buffer)
}
```

### Option 2: Send Default Frames Until Client Connects
Modify the default frame timer to run even when sink is active, but stop once real frames arrive.

### Option 3: Start Forwarding on Authorization
Begin forwarding frames as soon as `authorizedToStartStream` is called, not waiting for `startStream`.

## Implementation Steps

1. **Remove the streamingCounter check** in the sink-to-source bridge
2. **Always forward frames** when sink is active
3. **Let the source stream handle** whether to send to clients
4. **Add logging** to track when Photo Booth actually connects

## Expected Result
- Frames will flow: App → Sink → DeviceSource → Source Stream
- Photo Booth will see frames immediately upon selecting the camera
- This should trigger the proper `startStream()` call
- Video should appear in Photo Booth