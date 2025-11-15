# GigE Virtual Camera for macOS

[![Build and Release](https://github.com/ljchang/hyperstudy-gige/actions/workflows/build-and-release.yml/badge.svg)](https://github.com/ljchang/hyperstudy-gige/actions/workflows/build-and-release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-12.3+-blue.svg)](https://www.apple.com/macos/)
[![Platform](https://img.shields.io/badge/platform-Apple%20Silicon-lightgrey.svg)](https://support.apple.com/en-us/HT211814)

A native macOS application that creates virtual cameras from GigE Vision industrial cameras, making them available to any macOS application (Zoom, Teams, OBS, QuickTime, Photo Booth, etc.).

## Features

- **System Extension Architecture**: Implements a proper CMIO System Extension for virtual camera functionality
- **Native macOS Integration**: Appears as a standard camera in all macOS apps
- **Universal GigE Support**: Works with any GigE Vision compliant camera via Aravis library
- **Real-time Preview**: Built-in preview with camera status and controls
- **Professional Features**: Designed for industrial and professional camera integration
- **Notarized & Signed**: Properly signed with Developer ID for secure distribution

## Requirements

- macOS 12.3 (Monterey) or later  
- ARM64 (Apple Silicon) Mac
- GigE Vision compliant camera on the same network
- System Extension approval (first launch only)

## Installation

### Download

**[Download the latest release →](https://github.com/ljchang/hyperstudy-gige/releases/latest)**

### Installation Steps

1. **Download** the latest `GigEVirtualCamera-vX.X.X.dmg` from [Releases](https://github.com/ljchang/hyperstudy-gige/releases)
2. **Open** the DMG file
3. **Drag** GigEVirtualCamera.app to your Applications folder
4. **Launch** the app from Applications
5. **Approve** System Extension installation when prompted
6. **Allow** camera permissions in System Settings → Privacy & Security

**Note**: The app is signed and notarized with Apple Developer ID for secure installation.

### For Developers
See [BUILDING.md](BUILDING.md) for instructions on building from source.

## Building from Source

### Quick Start

```bash
# Clone the repository
git clone https://github.com/ljchang/hyperstudy-gige.git
cd hyperstudy-gige

# Install dependencies
brew install aravis

# Open in Xcode
open macos/GigEVirtualCamera.xcodeproj

# Build and run (Cmd+R)
```

For detailed build instructions, code signing, and distribution, see **[BUILDING.md](BUILDING.md)**.

### CI/CD

This project uses GitHub Actions for automated builds and releases:

- **Automatic Releases**: Push a version tag (e.g., `v1.0.0`) to automatically build, sign, notarize, and release
- **macOS Runners**: Built on Apple Silicon (macos-14)
- **Secure**: Uses GitHub Secrets for certificates and credentials
- **Workflow**: See [`.github/workflows/build-and-release.yml`](.github/workflows/build-and-release.yml)

For maintainers setting up CI/CD, see **[SECRETS_SETUP.md](SECRETS_SETUP.md)**.

## Usage

1. **First Launch**:
   - Approve System Extension installation when prompted
   - Allow camera permissions in System Settings
   - May require restart after first installation

2. **Using the App**:
   - Launch GigEVirtualCamera from Applications
   - Your GigE cameras will appear in the dropdown
   - Select a camera and click "Connect"
   - The virtual camera is now available system-wide

3. **In Other Apps**:
   - Open any camera-enabled app (Zoom, QuickTime, etc.)
   - Select "GigE Virtual Camera" from camera options
   - The GigE camera feed will appear

## Troubleshooting

### System Extension Issues

```bash
# Check if extension is installed
systemextensionsctl list

# Reset system extensions (requires SIP disabled)
systemextensionsctl reset

# View logs
log stream --predicate 'subsystem == "com.apple.cmio"'
```

### Camera Not Detected

- Verify camera is powered and connected to network
- Check if camera appears in: `arv-camera-test-0.8`
- Ensure firewall allows UDP port 3956 (GigE Vision)
- Try using camera's IP address directly

### Virtual Camera Not Appearing

1. Check System Settings → Privacy & Security → Camera
2. Ensure GigEVirtualCamera has permission
3. Restart the app or your Mac
4. For developers: Verify SIP is disabled for testing

### Build Issues

- Clean build: `xcodebuild clean`
- Reset derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Regenerate project: `xcodegen generate`

## Architecture

The project implements a macOS System Extension architecture:

### Components

- **GigECameraApp**: Main application
  - SwiftUI interface for camera selection and control
  - System Extension lifecycle management
  - Camera preview and status monitoring
  
- **GigECameraExtension**: CMIO System Extension
  - Implements `CMIOExtension` protocol
  - Provides virtual camera to macOS
  - Receives frames via CMIO sink stream API
  
- **Shared Components**:
  - `CameraManager`: Handles GigE camera discovery and control
  - `AravisBridge`: Objective-C++ wrapper for Aravis library
  - `CMIOFrameSender`: Manages frame transfer to extension
  - `ExtensionManager`: System Extension installation/activation

### Key Design Decisions

1. **System Extension**: Required for CMIO camera extensions (not App Extension)
2. **CMIO Sink/Source Pattern**: Uses Apple's recommended architecture for frame transfer
3. **Hardened Runtime**: Enabled with necessary entitlements for camera access
4. **Notarization**: Full Developer ID signing and notarization support

### Data Flow

1. GigE camera → Aravis → AravisBridge (C++ to Swift bridge)
2. CameraManager → CMIOFrameSender → CMIO sink stream
3. Extension receives frames → Provides to macOS as virtual camera
4. Apps access virtual camera through standard macOS camera APIs

## Contributing

Contributions are welcome! We appreciate bug reports, feature requests, documentation improvements, and code contributions.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to your branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Coding standards
- Testing guidelines
- Pull request process

### Areas for Contribution

- Camera format support (more pixel formats)
- Performance optimization
- Testing infrastructure
- Documentation improvements
- Bug fixes

See [open issues](https://github.com/ljchang/hyperstudy-gige/issues) for specific tasks.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [Aravis](https://github.com/AravisProject/aravis) - GigE Vision library
- Apple's Camera Extension sample code