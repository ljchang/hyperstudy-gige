# GigE Virtual Camera Design Overview

## Implementation Status

This document describes the architecture and implementation of the GigE Virtual Camera application for macOS. The application creates a virtual camera from GigE Vision cameras using the modern CMIOExtension framework implemented as a System Extension.

### Current Status (June 2025)

- ✅ **CMIO System Extension implemented** - Properly configured as System Extension (not App Extension)
- ✅ **Sink/Source stream architecture** - Fully implemented with CMIO sink stream API
- ✅ **System Extension lifecycle** - OSSystemExtensionRequest activation implemented
- ✅ **Test pattern generation** - Extension generates test patterns when no frames available
- ✅ **Multiple format support** - 1080p30, 720p60, 720p30, 480p30
- ✅ **Developer ID signing and notarization** - Full notarization workflow implemented
- ✅ **Build automation** - Separate scripts for development and release builds
- ✅ **Aravis integration** - Library properly bundled with fixed rpaths
- ✅ **CMIOFrameSender** - Properly finds and uses sink stream queue
- ⚠️ **System Extension entitlement** - Requires Apple approval for distribution
- ✅ **Extension architecture** - Properly loads as System Extension

### Key Architecture Changes from Original Design

1. **System Extension vs App Extension**: Based on Apple's documentation and WWDC sessions, CMIO camera extensions MUST be System Extensions, not App Extensions. This was a critical correction from the original implementation.

2. **Bundle Type**: Changed from `XPC!` to `SYSX` to properly identify as System Extension

3. **Embedding Location**: System Extensions must be embedded in `Contents/Library/SystemExtensions/`, not `Contents/PlugIns/`

4. **Activation Flow**: Added `ExtensionManager` class to handle OSSystemExtensionRequest for proper installation

## Part I: System Extension Architecture

### Section 1: Why System Extensions for CMIO

The foundation of our virtual camera implementation is the `CMIOExtension` framework, which MUST be implemented as a **System Extension** according to Apple's requirements. This is not optional - the CMIO framework specifically requires System Extension architecture for camera extensions.

#### Key Implementation Requirements:

1. **System Extension Package Type**: 
   - Bundle package type must be `SYSX`
   - Product type: `com.apple.product-type.system-extension`
   - Cannot use `com.apple.product-type.app-extension`

2. **Proper Embedding**:
   - Must be embedded in `Contents/Library/SystemExtensions/`
   - File extension: `.systemextension`

3. **Entitlements**:
   - Main app requires: `com.apple.developer.system-extension.install`
   - This is a restricted entitlement requiring Apple approval

4. **Activation**:
   - Uses `OSSystemExtensionRequest` API
   - Requires user approval in System Settings
   - Must be installed from /Applications

### Section 2: Core Components Implementation

Our implementation consists of three primary classes that implement the CMIOExtension protocols:

#### CameraProviderSource
- **Purpose**: Main entry point for the System Extension
- **Implementation**: `main.swift` calls `CMIOExtensionProvider.startService()`
- **Key features**:
  - Creates and manages device instances
  - Handles extension lifecycle
  - Manages client connections

#### CameraDeviceSource  
- **Purpose**: Represents the virtual camera device
- **Key features**:
  - Creates sink stream for receiving frames
  - Creates source stream for providing frames
  - Manages device properties and localization

#### CameraStreamSource
- **Purpose**: Handles video stream data flow
- **Key features**:
  - Implements CMIO sink/source pattern
  - Sink receives frames via `consumeSampleBuffer`
  - Source provides frames to client applications
  - Shared queue enables efficient frame passing

### Section 3: Frame Flow Architecture

The implementation uses Apple's recommended sink/source pattern:

```
Main App (GigECameraApp)
    ↓
AravisBridge (C++ → Swift)
    ↓
CMIOFrameSender
    ↓ (via CMIO sink stream)
System Extension (sink)
    ↓ (shared queue)
System Extension (source)
    ↓
Client Apps (QuickTime, Zoom, etc.)
```

Key implementation details:

1. **CMIOFrameSender**:
   - Properly discovers virtual camera device
   - Identifies sink stream (direction = 1)
   - Gets stream queue via `CMIOStreamCopyBufferQueue`
   - Sends frames as CMSampleBuffers

2. **Sink Stream**:
   - Receives frames in `consumeSampleBuffer`
   - No queue management needed (handled by CMIO)

3. **Source Stream**:
   - Provides frames to clients
   - Falls back to test pattern when no input

## Part II: Security and Distribution

### Section 4: Entitlements and Sandboxing

The System Extension architecture requires specific entitlements:

#### Main App Entitlements:
- `com.apple.developer.system-extension.install` (restricted, requires approval)
- `com.apple.security.app-sandbox`
- `com.apple.security.network.client` (for GigE camera access)
- `com.apple.security.network.server` (for GigE Vision protocol)
- `com.apple.security.application-groups`
- `com.apple.security.cs.disable-library-validation` (for Aravis libraries)
- `com.apple.security.cs.allow-unsigned-executable-memory`

#### Extension Entitlements:
- `com.apple.security.app-sandbox`
- `com.apple.security.application-groups`

### Section 5: Code Signing and Notarization

Proper signing order is critical:

1. **Inside-out signing**:
   - Sign all frameworks/libraries first
   - Sign System Extension
   - Sign main app last

2. **Provisioning Profiles**:
   - Development: Uses provisioning profile with devices
   - Release: NO provisioning profile for Developer ID distribution

3. **Notarization Process**:
   - Build with Developer ID certificate
   - Remove provisioning profile for release
   - Submit to notarization
   - Staple ticket
   - Verify with spctl

### Section 6: Distribution Challenges

#### Current Status:
- ✅ Properly signed with Developer ID
- ✅ Successfully notarized
- ❌ Cannot run without special entitlement approval

#### Required for Distribution:
1. **Apple Approval**: Must request `com.apple.developer.system-extension.install` entitlement
2. **Development Testing**: Requires SIP disabled (`csrutil enable --without sysext`)
3. **Distribution Options**:
   - Direct distribution after Apple approval
   - Mac App Store (might have different requirements)

## Part III: Implementation Details

### Section 7: Build System

The project uses XcodeGen for project generation:

```yaml
targets:
  GigEVirtualCamera:
    type: application
    platform: macOS
    
  GigECameraExtension:
    type: system-extension  # Critical: not app-extension
    platform: macOS
```

Key build scripts:
- `build_dev.sh`: Development builds with Apple Development signing
- `build_release.sh`: Release builds with Developer ID + optional notarization
- `notarize.sh`: Comprehensive notarization workflow

### Section 8: Current Limitations

1. **Entitlement Approval**: The main blocker is getting Apple's approval for the System Extension entitlement

2. **Development Workflow**: Requires SIP modification for testing

3. **Distribution**: Cannot distribute outside App Store without entitlement approval

## Conclusions

The GigE Virtual Camera successfully implements a CMIO System Extension architecture for creating virtual cameras from GigE Vision sources. The implementation is complete and functional, with proper:

- System Extension configuration
- CMIO sink/source implementation  
- Developer ID signing and notarization
- Aravis integration for GigE cameras

The only remaining step for distribution is obtaining Apple's approval for the `com.apple.developer.system-extension.install` entitlement. Until then, development and testing requires disabling SIP restrictions on test machines.

### Architecture Summary

```
┌─────────────────────┐     ┌─────────────────────────┐
│   GigE Camera       │     │    Main App Process     │
│                     │     │  (/Applications)        │
│                     │◀────│  AravisBridge           │
└─────────────────────┘     │  CameraManager          │
                            │  CMIOFrameSender        │
                            └───────────┬─────────────┘
                                        │
                                        │ CMIO Sink API
                                        │
                            ┌───────────▼─────────────┐
                            │  System Extension       │
                            │  (SYSX bundle)          │
                            │                         │
                            │  Sink Stream            │
                            │  ↓ (shared queue)       │
                            │  Source Stream          │
                            └───────────┬─────────────┘
                                        │
                                        │ Virtual Camera
                                        ▼
                            ┌─────────────────────────┐
                            │   Client Applications   │
                            │   (QuickTime, Zoom,     │
                            │    Photo Booth, etc.)   │
                            └─────────────────────────┘
```

This architecture provides proper system integration with security isolation and efficient frame passing.