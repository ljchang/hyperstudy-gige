# GigE Virtual Camera Implementation Guide

## Current Status

✅ **Completed:**
- Project structure created
- Minimal SwiftUI app interface
- CoreMediaIO extension framework
- Test pattern generation
- Format switching support
- Library bundling scripts
- Entitlements and Info.plist files

⏳ **Next Steps:**
1. Create Xcode project
2. Build and test with test pattern
3. Integrate Aravis bridge
4. Connect to real GigE camera

## Creating the Xcode Project

### Option 1: Using XcodeGen (Recommended)
```bash
# Install xcodegen
brew install xcodegen

# Generate project
cd macos
xcodegen generate
```

### Option 2: Manual Creation

1. Open Xcode and create new macOS App
   - Product Name: GigEVirtualCamera
   - Team: Luke Chang (S368GH6KF7)
   - Bundle ID: com.lukechang.GigEVirtualCamera
   - Interface: SwiftUI
   - Language: Swift

2. Add System Extension Target
   - File → New → Target
   - Search for "System Extension"
   - Choose "Camera Extension"
   - Product Name: GigECameraExtension
   - Bundle ID: com.lukechang.GigEVirtualCamera.Extension

3. Configure Build Settings
   - Set deployment target to macOS 12.3
   - Enable "Automatically manage signing"
   - Add app groups capability to both targets

4. Add Files
   - Drag all Swift files to appropriate targets
   - Set target membership correctly
   - Add entitlement files

5. Add Build Phase for Library Bundling
   - Select app target
   - Build Phases → + → New Run Script Phase
   - Script: `${SRCROOT}/Scripts/bundle_libraries.sh`

## Testing the Extension

1. Build and run the app
2. Click "Install Extension"
3. Approve in System Settings if prompted
4. Open QuickTime Player
5. File → New Movie Recording
6. Select "GigE Virtual Camera" from camera dropdown
7. You should see color bars test pattern

## Integrating Aravis

The next step is to create the Aravis bridge:

1. Create `AravisBridge.h` and `AravisBridge.mm`
2. Link against bundled Aravis libraries
3. Replace test pattern with real camera frames

## Architecture Overview

```
App Launch
    ↓
Install Extension → System Extension Manager
    ↓                        ↓
Camera Manager          Extension Process
    ↓                        ↓
Status Updates          Provider Source
                             ↓
                        Device Source
                             ↓
                        Stream Source
                             ↓
                        Aravis Bridge
                             ↓
                        GigE Camera
```

## Debugging Tips

1. **Extension Logs:**
   ```bash
   # View extension logs
   log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"'
   ```

2. **Check Extension Status:**
   ```bash
   systemextensionsctl list
   ```

3. **Reset Extensions:**
   ```bash
   systemextensionsctl reset
   ```

4. **Common Issues:**
   - Extension not appearing: Check code signing
   - No video: Check Console for errors
   - Crashes: Look for crash logs in Console.app

## Performance Targets

- CPU usage < 10% at 1080p30
- Memory < 100MB
- Latency < 50ms
- Zero frame drops under normal load

## Next Development Phase

1. **Aravis Integration** (Week 1)
   - Create Objective-C++ bridge
   - Handle camera discovery
   - Frame capture and conversion

2. **Polish** (Week 2)
   - Error handling
   - Reconnection logic
   - Performance optimization
   - User documentation