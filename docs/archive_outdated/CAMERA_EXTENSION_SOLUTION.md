# GigE Virtual Camera Extension - Architecture Overview

## Current Implementation

The GigE Virtual Camera uses Apple's CMIOExtension framework to create a system-wide virtual camera that appears in all macOS applications.

### Architecture

```
┌─────────────────────────┐     ┌─────────────────────────┐
│    GigECameraApp        │     │  GigECameraExtension    │
│                         │     │                         │
│  - UI/Settings          │     │  - CMIOExtension        │
│  - Aravis Integration   │     │  - Virtual Camera       │
│  - Camera Discovery     │     │  - Stream Provider      │
│  - GigECameraManager ◄──┼─────┼──► GigECameraManager    │
│                         │     │    (shared instance)    │
└─────────────────────────┘     └─────────────────────────┘
        │                                    │
        └────────────────────────────────────┘
              Both access same shared
              GigECameraManager instance
```

### Key Components

1. **GigECameraApp** (Main Application)
   - Manages UI and user settings
   - Discovers GigE cameras via Aravis
   - Controls camera connection and streaming
   - Handles camera preview display

2. **GigECameraExtension** (CMIOExtension)
   - Registers virtual camera with macOS
   - Provides video stream to client applications
   - Directly accesses frames from GigECameraManager
   - No XPC communication needed

3. **GigECameraManager** (Shared Component)
   - Singleton instance accessible by both app and extension
   - Wraps Aravis library for GigE camera communication
   - Manages frame distribution to multiple handlers
   - Handles camera connection state

4. **AravisBridge** (Objective-C++)
   - Bridges Aravis C library to Swift
   - Handles frame capture and pixel format conversion
   - Supports various Bayer patterns and color formats

## Simplified Architecture Benefits

The current implementation eliminates complexity by:
- **No XPC Communication**: Extension directly uses GigECameraManager
- **No System Extension**: Uses CMIOExtension which doesn't require admin approval
- **Shared Memory**: Both processes access the same camera manager instance
- **Direct Frame Access**: Extension gets frames directly without serialization

## Requirements

### Entitlements
- **App**: App Sandbox, Network Client, App Groups
- **Extension**: App Sandbox, App Groups
- **NOT Required**: System Extension Install, Camera Access

### Code Signing
- Development: Standard Apple Development certificate
- Distribution: Developer ID certificate (for notarization)

## Building and Testing

1. **Build the app** with proper entitlements
2. **Copy to /Applications** (required for extension to load)
3. **Run the app** - extension loads automatically
4. **Select camera** in the app UI
5. **Use in other apps** - "GigE Virtual Camera" appears in camera menus

## Troubleshooting

### Virtual Camera Not Appearing
1. Ensure app is in /Applications
2. Check Console.app for extension loading errors
3. Verify entitlements are correct
4. Try `systemextensionsctl reset` if needed

### No Frames in Client Apps
1. Verify GigE camera is connected in main app
2. Check that streaming is active
3. Look for frame distribution logs in Console
4. Ensure camera format is supported

## Current Status
✅ CMIOExtension properly implemented
✅ Direct frame access (no XPC needed)
✅ Aravis integration complete
✅ Multiple pixel format support
✅ Frame distribution working
✅ Entitlements properly configured

The architecture is production-ready and follows Apple's recommended patterns for camera extensions.