# Single IOSurface Simplification

## Changes Made

### Before (Ring Buffer - Complex)
- Extension created 3 IOSurfaces
- App rotated through them with `currentIndex = (currentIndex + 1) % 3`
- Extension had to figure out which surface had the latest frame
- Potential synchronization issues

### After (Single Buffer - Simple)
- Extension creates only 1 IOSurface
- App always writes to index 0
- Extension always reads from index 0
- No index calculation needed

## Code Changes

1. **Extension** (`GigEVirtualCameraExtensionProvider.swift`):
   ```swift
   private let poolSize = 1  // Simplified to single buffer
   ```

2. **App** (`IOSurfaceFrameWriter.swift`):
   ```swift
   frameIndex += 1
   // Simplified: always use index 0 (single buffer)
   currentIndex = 0
   ```

## Benefits for Debugging

1. **Eliminates sync issues**: No need to coordinate which buffer is current
2. **Simpler logs**: Always know we're using IOSurface at index 0
3. **Easier to trace**: Frame goes to one place, read from one place
4. **Less state**: Only track frame index, not buffer index

## Next Steps

1. Restart the app
2. In the app:
   - Uninstall and reinstall the extension
   - Connect to camera
   - Click "Show Preview" to start streaming
3. Monitor with simplified script:
   ```bash
   ./Scripts/debug_frame_flow_complete.sh
   ```

Once basic frame flow works with single buffer, we can add back ring buffer for performance.