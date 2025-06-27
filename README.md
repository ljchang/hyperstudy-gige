# GigE Virtual Camera for macOS

A native macOS application that creates a virtual camera from GigE Vision cameras, enabling use with any macOS application that supports cameras (Zoom, Teams, OBS, QuickTime, etc.).

## Features

- **Native macOS Integration**: Appears as a standard camera in System Settings
- **Universal GigE Support**: Works with any GigE Vision compliant camera via Aravis
- **Virtual Camera**: Creates a macOS Camera Extension for system-wide use
- **Real-time Preview**: Built-in preview window with camera controls
- **Easy Installation**: Simple drag-and-drop installation

## Requirements

- macOS 13.0 (Ventura) or later
- GigE Vision compliant camera
- Network connection to camera

## Installation

1. Download the latest release from the Releases page
2. Open the DMG file and drag GigEVirtualCamera.app to Applications
3. Launch the app and follow the setup instructions
4. Grant necessary permissions when prompted

## Building from Source

### Prerequisites

- Xcode 14.0 or later
- macOS 13.0 SDK or later
- Homebrew (for dependencies)

### Build Steps

```bash
# Clone the repository
git clone https://github.com/yourusername/hyperstudy-gige.git
cd hyperstudy-gige

# Install dependencies
cd macos
./Scripts/setup_dependencies.sh

# Build the app
./Scripts/build_release.sh

# The built app will be at: macos/build/Release/GigEVirtualCamera.app
```

### Development

Open `macos/GigEVirtualCamera.xcodeproj` in Xcode for development.

## Usage

1. **Launch the App**: Open GigEVirtualCamera from Applications
2. **Select Camera**: Choose your GigE camera from the dropdown
3. **Start Streaming**: Click "Start" to begin streaming
4. **Use in Apps**: Select "GigE Virtual Camera" in any app's camera settings

## Troubleshooting

### Camera Not Detected

- Ensure camera is connected to the same network
- Check firewall settings allow GigE Vision traffic
- Try refreshing the camera list

### Virtual Camera Not Appearing

- Restart the app
- Check System Settings > Privacy & Security > Camera
- Reinstall the camera extension: `./Scripts/reinstall_extension.sh`

### Performance Issues

- Reduce camera resolution or frame rate
- Ensure good network connection to camera
- Close other resource-intensive applications

## Architecture

The project uses a simplified architecture where both the main app and camera extension share the same camera manager instance:

- **GigECameraApp**: Main application with UI, camera discovery, and settings
- **GigECameraExtension**: CMIOExtension that provides the virtual camera to macOS
- **GigECameraManager**: Shared singleton that handles camera communication for both app and extension
- **AravisBridge**: Objective-C++ wrapper around the Aravis GigE Vision library
- **Shared**: Common code including camera management and frame distribution

Key benefits:
- No complex IPC or XPC communication needed
- Direct frame access in the extension
- Simplified debugging and maintenance
- Better performance with less overhead

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