# GigE Virtual Camera for macOS

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

### For End Users (Coming Soon)
1. Download the latest release DMG
2. Drag GigEVirtualCamera.app to Applications
3. Launch and approve System Extension installation
4. Grant camera permissions when prompted

### For Developers (Current)
**Note**: The app requires Apple's approval for the System Extension entitlement. Until approved, development requires disabling SIP on test machines.

## Building from Source

### Prerequisites

- Xcode 15.0 or later
- macOS 14.0 SDK or later  
- [Homebrew](https://brew.sh) (for Aravis dependency)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Apple Developer account with Developer ID certificate

### Build Steps

```bash
# Clone the repository
git clone https://github.com/yourusername/hyperstudy-gige.git
cd hyperstudy-gige

# Install dependencies
brew install aravis
brew install xcodegen

# Build the app
./Scripts/build_release.sh

# For development builds (uses Apple Development signing)
./Scripts/build_dev.sh
```

### Development Setup

1. **Disable SIP for testing** (development only):
   ```bash
   # Boot into Recovery Mode
   # Open Terminal and run:
   csrutil enable --without sysext
   # Restart
   ```

2. **Open in Xcode**:
   ```bash
   xcodegen generate
   open GigEVirtualCamera.xcodeproj
   ```

3. **Select your development team** in Xcode project settings

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

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [Aravis](https://github.com/AravisProject/aravis) - GigE Vision library
- Apple's Camera Extension sample code