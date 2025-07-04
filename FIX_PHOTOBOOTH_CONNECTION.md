# Fix Photo Booth Connection Issue

## Problem Summary
Photo Booth can see the "GigE Virtual Camera" but shows a black screen. Frames are flowing through the entire pipeline (App → Sink → DeviceSource → Source → CMIO) but Photo Booth isn't calling `authorizedToStartStream` or `startStream`.

## Root Cause Analysis
The issue appears to be that Photo Booth needs to see frames immediately when it queries the camera, but our source stream only starts sending frames after `startStream()` is called. This creates a deadlock:

1. Photo Booth queries the camera
2. Expects to see frames to validate the camera
3. Won't call `startStream()` without seeing frames
4. But we only send frames after `startStream()` is called

## Solution: Always-On Frame Generation

The source stream should ALWAYS be sending frames, regardless of client connection state. This ensures:
1. Photo Booth sees frames immediately when querying
2. The camera appears "live" to any application
3. No deadlock between frame availability and connection

## Implementation Changes Made

1. **Start default frame timer on init** - The source stream now starts its default frame timer immediately when created, not waiting for `startStream()`

2. **Always send frames** - Removed the check that only sent default frames when sink wasn't active. Now always sends frames.

3. **Option 3 implementation** - Added logging in `authorizedToStartStream` to track when clients try to connect

## Next Debug Steps

If Photo Booth still won't connect:

1. **Check frame format compatibility** - Ensure the 512x512 BGRA format is acceptable to Photo Booth
2. **Verify timing** - Make sure frames are being sent at exactly 30fps 
3. **Check stream properties** - Ensure all required properties are exposed
4. **Test with different frame patterns** - Try solid colors instead of test pattern
5. **Compare with working CMIO extensions** - See how other virtual cameras handle the initial connection

## Alternative Approaches

1. **Send frames before stream.send()** - Queue frames internally and flush when client connects
2. **Use CVDisplayLink** - Tie frame generation to display refresh for better timing
3. **Implement preview stream** - Some CMIO extensions have a separate preview stream
4. **Check entitlements** - Ensure the extension has all required entitlements for camera access