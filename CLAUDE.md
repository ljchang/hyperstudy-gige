# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a native macOS application that creates a virtual camera from GigE Vision cameras. The app uses:
- Swift and SwiftUI for the main application
- macOS Camera Extension API for virtual camera functionality
- Aravis library (via Objective-C++ bridge) for GigE Vision camera support

## Common Development Commands

### Building the Application

```bash
# Build debug version
cd macos
xcodebuild -project GigEVirtualCamera.xcodeproj -scheme GigECameraApp -configuration Debug

# Build release version
xcodebuild -project GigEVirtualCamera.xcodeproj -scheme GigECameraApp -configuration Release

# Or use the convenience scripts:
./Scripts/build_debug.sh
./Scripts/build_release.sh
```

**IMPORTANT**: DO NOT run `xcodegen` as it breaks the manual provision profile settings. Use the existing project file and build directly.

### Installing and Testing

```bash
# Install the built app
./Scripts/install_app.sh

# Reinstall camera extension (if virtual camera not appearing)
./Scripts/reinstall_extension.sh

# Run the app from command line (for debugging)
open /Applications/GigEVirtualCamera.app
```

### Development in Xcode

```bash
# Open project in Xcode
open macos/GigEVirtualCamera.xcodeproj
```

## Architecture Overview

### Project Structure

```
macos/
├── GigECameraApp/          # Main application
│   ├── ContentView.swift   # Main UI
│   ├── AppDelegate.swift   # App lifecycle
│   └── Info.plist         # App configuration
├── GigECameraExtension/    # Camera Extension
│   ├── ExtensionProvider.swift  # Camera extension implementation
│   └── Info.plist         # Extension configuration
├── Shared/                 # Shared code
│   ├── AravisBridge/      # Objective-C++ Aravis wrapper
│   ├── CameraManager.swift # Camera discovery and management
│   └── CameraFrameSender.swift # Frame passing between app and extension
├── Scripts/               # Build and utility scripts
└── Resources/            # Assets and licenses
```

### Key Components

1. **AravisBridge** (`Shared/AravisBridge/`)
   - Objective-C++ wrapper around Aravis C library
   - Handles GigE Vision camera discovery and frame acquisition
   - Converts Aravis frames to CVPixelBuffer for macOS

2. **Camera Extension** (`GigECameraExtension/`)
   - Implements CMIOExtension protocol
   - Receives frames from main app via XPC
   - Provides virtual camera to macOS system

3. **Main Application** (`GigECameraApp/`)
   - SwiftUI interface for camera selection and preview
   - Manages camera connection and streaming
   - Sends frames to extension via XPC

### Key Design Patterns

- **XPC Communication**: Main app communicates with extension using XPC for frame data
- **Singleton Pattern**: CameraManager uses singleton for camera state
- **Bridge Pattern**: AravisBridge wraps C++ Aravis API for Swift consumption
- **Delegation**: Camera events handled via delegate pattern

### Common Tasks

#### Adding New Camera Features

1. Update AravisBridge to expose new Aravis functionality
2. Add Swift wrapper methods in CameraManager
3. Update UI in ContentView to expose controls

#### Debugging Camera Issues

```bash
# Check if Aravis can see cameras
brew install aravis
arv-camera-test-0.8

# Check system logs for extension issues
log stream --predicate 'subsystem == "com.hyperstudy.GigEVirtualCamera"'

# Debug extension loading
systemextensionsctl list
```

#### Modifying Frame Processing

Frame pipeline:
1. Aravis captures frame → `AravisBridge::getFrame()`
2. Convert to CVPixelBuffer → `AravisBridge` 
3. Send via XPC → `CameraFrameSender`
4. Receive in extension → `ExtensionProvider`
5. Provide to macOS → `CMIOExtension` stream

### Testing

```bash
# Test virtual camera appears in system
system_profiler SPCameraDataType | grep "GigE Virtual Camera"

# Test in QuickTime
open -a "QuickTime Player"
# File → New Movie Recording → Select "GigE Virtual Camera"
```

#### Using the Test Camera

When no real GigE camera is available:
1. Launch the app
2. Select "Test Camera (Aravis Simulator)" from the dropdown
3. Click Connect and Start Streaming
4. The app uses Aravis's built-in fake camera for testing

### Common Issues and Solutions

1. **Virtual camera not appearing**
   - Restart System Extension: `systemextensionsctl reset`
   - Check extension is approved in System Settings
   - Reinstall: `./Scripts/reinstall_extension.sh`

2. **Camera discovery fails**
   - Check network connectivity to camera
   - Verify firewall allows GigE Vision traffic
   - Test with `arv-camera-test-0.8`

3. **Build errors**
   - Ensure Aravis is installed: `brew install aravis`
   - Clean build folder: `rm -rf macos/build`
   - Reset package cache: `rm -rf ~/Library/Developer/Xcode/DerivedData`

### Code Style Guidelines

- Use Swift style guide conventions
- Keep Objective-C++ code minimal in AravisBridge
- Prefer Swift native types over Foundation when possible
- Use async/await for asynchronous operations
- Add documentation comments for public APIs