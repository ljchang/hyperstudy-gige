# Building GigE Virtual Camera

This guide explains how to build GigE Virtual Camera from source on your local machine.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Environment Configuration](#environment-configuration)
- [Building](#building)
- [Code Signing](#code-signing)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

1. **macOS 12.3 or later** (Monterey+)
2. **Apple Silicon Mac** (arm64 architecture)
3. **Xcode 15.0+**
   ```bash
   xcode-select --install
   ```

4. **Homebrew**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

5. **Aravis Library**
   ```bash
   brew install aravis
   ```

### Optional Tools

- **XcodeGen** (if you need to regenerate the Xcode project)
  ```bash
  brew install xcodegen
  ```
  **Note:** AVOID running `xcodegen` unless absolutely necessary, as it can break manual provisioning profile settings.

## Quick Start

### For Contributors (Without Code Signing)

If you just want to build and test the app locally without distribution:

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/hyperstudy-gige.git
cd hyperstudy-gige

# 2. Install dependencies
brew install aravis

# 3. Open in Xcode
open macos/GigEVirtualCamera.xcodeproj

# 4. Build and run
# Select "GigEVirtualCamera" scheme
# Press Cmd+R to build and run
```

**Note:** Without proper code signing, the system extension may not activate, but you can still develop and test the camera integration code.

### For Distribution Builds

If you have an Apple Developer account and want to create distributable builds:

```bash
# 1. Set up your environment variables
cp .env.example .env
# Edit .env and fill in your Apple Developer credentials

# 2. Build
cd macos
xcodebuild -project GigEVirtualCamera.xcodeproj \
  -scheme GigEVirtualCamera \
  -configuration Release

# 3. For full distribution (notarization + DMG)
./Scripts/build_and_distribute.sh
```

## Environment Configuration

### Setting Up .env File

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and configure your settings:
   ```bash
   # Apple Developer Configuration
   APPLE_TEAM_ID=YOUR_10_CHAR_TEAM_ID
   CODE_SIGN_IDENTITY=Developer ID Application
   BUNDLE_ID_PREFIX=com.yourcompany

   # Notarization (for distribution builds only)
   NOTARIZATION_APPLE_ID=your.email@example.com
   NOTARIZATION_PASSWORD=xxxx-xxxx-xxxx-xxxx  # App-specific password
   NOTARIZATION_TEAM_ID=YOUR_10_CHAR_TEAM_ID
   ```

3. Source the environment file before building:
   ```bash
   source .env
   ```

### Finding Your Team ID

1. Go to https://developer.apple.com/account/#!/membership
2. Sign in with your Apple ID
3. Your Team ID is shown under "Membership Information"
4. It's a 10-character alphanumeric string (e.g., S368GH6KF7)

### Creating App-Specific Password

For notarization, you need an app-specific password:

1. Go to https://appleid.apple.com/account/manage
2. Sign in
3. Under "Security" → "App-Specific Passwords"
4. Click "Generate Password"
5. Label it "GigE Virtual Camera Notarization"
6. Copy the generated password to your `.env` file

## Building

### Debug Build

For development and testing:

```bash
cd macos
xcodebuild -project GigEVirtualCamera.xcodeproj \
  -scheme GigEVirtualCamera \
  -configuration Debug \
  build
```

Or use Xcode:
1. Open `macos/GigEVirtualCamera.xcodeproj`
2. Select "GigEVirtualCamera" scheme
3. Choose Debug configuration
4. Press Cmd+B to build

The app will be built to:
```
macos/build/DerivedData/Build/Products/Debug/GigEVirtualCamera.app
```

### Release Build

For distribution-ready builds:

```bash
cd macos
xcodebuild -project GigEVirtualCamera.xcodeproj \
  -scheme GigEVirtualCamera \
  -configuration Release \
  build
```

### Full Distribution Build

To build, sign, notarize, and create a DMG:

```bash
./Scripts/build_and_distribute.sh
```

This script will:
1. Clean previous builds
2. Build the Release configuration
3. Sign with Developer ID
4. Notarize with Apple
5. Create a DMG installer
6. Notarize the DMG

Output will be in: `build/distribution/`

## Code Signing

### Development Signing

For local development, use your personal Apple Development certificate:

1. Open Xcode Preferences → Accounts
2. Add your Apple ID
3. Download your development certificate
4. Xcode will handle signing automatically for Debug builds

### Distribution Signing

For distributable builds, you need:

1. **Developer ID Application Certificate**
   - Obtain from Apple Developer Portal
   - Install in Keychain Access

2. **Provisioning Profiles**
   - Main App: "GigE Virtual Camera Distribution"
   - Extension: "GigE Camera Extension Distribution"
   - Download from Apple Developer Portal
   - Place in `~/Library/MobileDevice/Provisioning Profiles/`

3. **Entitlements**
   - System Extension Installation (requires Apple approval)
   - Camera access
   - Network access
   - Hardened Runtime

### Signing Manually

To sign an already-built app:

```bash
./Scripts/sign_developer_id.sh /path/to/GigEVirtualCamera.app
```

### Verifying Signatures

```bash
# Verify app signature
codesign --verify --deep --strict /Applications/GigEVirtualCamera.app

# Check signing details
codesign -dvvv /Applications/GigEVirtualCamera.app

# Verify notarization
spctl -a -vv /Applications/GigEVirtualCamera.app
```

## Testing

### Running the App

After building:

```bash
# Install to /Applications (build scripts do this automatically)
open /Applications/GigEVirtualCamera.app
```

### Testing System Extension

The system extension requires approval on first run:

1. Launch the app
2. macOS will prompt for system extension approval
3. Go to System Settings → Privacy & Security
4. Click "Allow" next to the extension request
5. Restart the app

### Testing with Virtual Camera

1. Launch GigEVirtualCamera
2. Select "Test Camera (Aravis Simulator)" from dropdown
3. Click "Connect" then "Start Streaming"
4. Open another app (e.g., QuickTime Player)
5. File → New Movie Recording
6. Select "GigE Virtual Camera" as the camera

### Verifying Virtual Camera

Check if the virtual camera is available:

```bash
# List all cameras
system_profiler SPCameraDataType

# Check extension status
systemextensionsctl list

# Monitor extension logs
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"'
```

## Troubleshooting

### Common Build Errors

#### "Aravis not found"

```bash
# Install Aravis
brew install aravis

# Verify installation
brew list aravis
pkg-config --modversion aravis-0.8
```

#### "Provisioning profile not found"

For distribution builds, ensure provisioning profiles are installed:
```bash
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/
```

If missing, download from Apple Developer Portal.

#### "Code signing failed"

1. Check your certificate is valid:
   ```bash
   security find-identity -v -p codesigning
   ```

2. Ensure Team ID matches your certificate:
   ```bash
   # In .env file
   APPLE_TEAM_ID=YOUR_ACTUAL_TEAM_ID
   ```

3. For Developer ID, ensure you're using Manual signing

### Runtime Issues

#### "System extension not found"

```bash
# Reset system extensions
systemextensionsctl reset

# Rebuild and reinstall
./Scripts/reinstall_extension.sh
```

#### "Virtual camera not appearing"

1. Check extension is approved in System Settings
2. Restart the app
3. Check logs for errors:
   ```bash
   log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' --last 5m
   ```

#### "Camera discovery fails"

For GigE cameras:
1. Check network connectivity
2. Verify firewall allows GigE Vision traffic
3. Test with Aravis command-line tools:
   ```bash
   arv-camera-test-0.8
   ```

### Dependency Version Issues

If you get errors about Aravis version mismatches:

1. Check installed Aravis version:
   ```bash
   brew info aravis
   ```

2. Update header paths in `project.yml` if needed:
   ```yaml
   HEADER_SEARCH_PATHS:
     - /opt/homebrew/Cellar/aravis/VERSION/include/aravis-0.8
   ```

3. Or use symlinked paths (recommended):
   ```yaml
   HEADER_SEARCH_PATHS:
     - /opt/homebrew/opt/aravis/include/aravis-0.8
   ```

### Clean Build

If you encounter persistent issues:

```bash
# Clean all build artifacts
rm -rf macos/build
rm -rf macos/DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*GigE*

# Clean and rebuild
cd macos
xcodebuild clean
xcodebuild build
```

## Build Architecture

### Project Structure

```
macos/
├── GigECameraApp/              # Main application
│   ├── ContentView.swift       # UI
│   └── Info.plist
├── GigECameraExtension/        # System extension
│   ├── ExtensionProvider.swift
│   └── Info.plist
├── Shared/                     # Shared code
│   ├── AravisBridge/          # Aravis wrapper (Objective-C++)
│   └── CameraManager.swift    # Camera management
└── Scripts/                   # Build scripts
```

### Build Process

1. **Pre-build**: Make scripts executable
2. **Compile**: Swift and Objective-C++ sources
3. **Post-build**:
   - Bundle Aravis libraries
   - Fix library paths
   - Copy to /Applications
   - Fix extension naming
4. **Distribution** (if enabled):
   - Sign all components
   - Notarize app
   - Create DMG
   - Notarize DMG

### Dependencies

**Build-time:**
- Xcode toolchain
- Aravis headers and libraries
- GLib, GIO, GObject

**Runtime:**
- Bundled Aravis libraries (included in app)
- System frameworks (SystemExtensions, CoreMediaIO)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Code style
- Submitting pull requests
- Testing requirements
- Development workflow

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Camera Extensions](https://developer.apple.com/documentation/coremediaio/creating_a_camera_extension_with_core_media_i_o)
- [System Extensions](https://developer.apple.com/documentation/systemextensions)
- [Aravis Documentation](https://aravisproject.github.io/aravis/)
- [Notarization](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

## Getting Help

- **Build Issues**: Check this document and GitHub Issues
- **Runtime Issues**: Enable debug logging and check system logs
- **Code Signing**: See Apple's code signing documentation
- **Community**: Open a GitHub Discussion or Issue

---

For CI/CD and release management, see [SECRETS_SETUP.md](SECRETS_SETUP.md).
