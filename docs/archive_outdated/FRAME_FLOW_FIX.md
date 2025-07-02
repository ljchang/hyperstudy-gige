# Frame Flow Architecture Fix

## Current Issue Summary

The app is incorrectly trying to use the CMIO sink stream to send frames to the extension. This is failing because:

1. **Sink streams are NOT for our app** - they're for OTHER apps (like video conferencing apps) to send frames TO our extension
2. **Photo Booth only reads from source streams** - it never writes to sink streams
3. **The queue fills up** because no one is consuming from it

## How CMIO Extensions Actually Work

Based on the CMIO Extensions Developer Guide and the current logs:

1. **Source Stream**: Extension → Client Apps (Photo Booth, Zoom, etc.)
   - This is working! Photo Booth connects and waits for frames
   
2. **Sink Stream**: Client Apps → Extension  
   - NOT for our main app to use
   - For apps like OBS to send frames for processing

## The Solution

Since the extension is sandboxed and can't access the network or Aravis directly, we need to:

1. **Keep the current app architecture** - App captures frames from GigE camera
2. **Change how frames get to the extension** - Use App Groups shared memory or XPC
3. **Extension receives frames and outputs via source stream** - This part is already working

## Quick Fix Options

### Option 1: Test Pattern in Extension (Immediate Testing)
The extension already has the ability to generate test frames. We could re-enable this to verify Photo Booth works.

### Option 2: Shared Memory via App Groups
1. App writes frames to shared memory using IOSurface
2. Extension reads frames from shared memory
3. Extension sends frames through source stream

### Option 3: Custom XPC Service
1. Create a dedicated XPC service for frame transfer
2. More complex but more robust

## Why The Current Approach Fails

The CMIOFrameSender is trying to use the sink stream as if it were a direct pipe to the extension, but:
- The sink stream queue is only created when a CLIENT app (not our app) wants to send frames
- Photo Booth never creates this queue because it only wants to receive frames
- Our app is essentially talking to a non-existent queue

## Recommendation

For now, the quickest fix is to:
1. Re-enable test pattern generation in the extension to verify Photo Booth works
2. Then implement proper frame passing via App Groups shared memory

This aligns with Apple's intended architecture where the extension is the source of frames for client apps.