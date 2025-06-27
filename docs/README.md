# GigE Virtual Camera for macOS

A native macOS virtual camera that exposes GigE Vision cameras as standard webcams using CoreMediaIO Camera Extension.

## Features

- Zero configuration - works out of the box
- Native macOS integration
- Appears in all video apps (Zoom, Teams, QuickTime, etc.)
- Minimal, elegant interface
- Bundled Aravis - no dependencies

## Developer Information

- Team Name: Luke Chang
- Team ID: S368GH6KF7
- Bundle ID Prefix: com.lukechang

## Project Structure

```
macos/
├── GigEVirtualCamera.xcodeproj    # Xcode project
├── GigECameraApp/                 # Main application
├── GigECameraExtension/           # Camera extension
├── Shared/                        # Shared code
├── AravisBridge/                  # Aravis C++ bridge
└── Scripts/                       # Build scripts
```

## Build Requirements

- macOS 12.3+ (Monterey or later)
- Xcode 14+
- Apple Developer account
- Aravis libraries (bundled)

## Quick Start

1. Open `GigEVirtualCamera.xcodeproj` in Xcode
2. Select your development team
3. Build and run
4. Click "Install Extension" in the app
5. Your GigE camera now appears as "GigE Virtual Camera" in all apps

## Architecture

The project consists of:
- **Container App**: Minimal SwiftUI interface for status and installation
- **Camera Extension**: CoreMediaIO extension that provides the virtual camera
- **Aravis Bridge**: Objective-C++ wrapper around Aravis for GigE camera access