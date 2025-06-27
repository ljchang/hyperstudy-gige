# Setting Up System Extension Provisioning

## Requirements

1. **Apple Developer Account with System Extension Capability**
   - Go to https://developer.apple.com/account
   - Certificates, Identifiers & Profiles → Identifiers
   - Create/Edit your App ID (com.lukechang.GigEVirtualCamera)
   - Enable "System Extension" capability

2. **Create Provisioning Profiles**
   
   For the main app:
   - Profiles → Create a new profile
   - Select "macOS App Development"
   - Select your App ID
   - Select your certificate
   - Name it "GigE Virtual Camera Dev"
   
   For the extension:
   - Create another profile for com.lukechang.GigEVirtualCamera.Extension
   - Also enable System Extension capability

3. **Download and Install Profiles**
   - Download both .provisionprofile files
   - Double-click to install in Xcode

4. **Update Xcode Project**
   - In Xcode, select the project
   - For each target, go to Signing & Capabilities
   - Change from "Automatically manage signing" to manual
   - Select the appropriate provisioning profile

## Alternative: Test Without System Extension

Since system extensions are complex, here's a simpler approach for testing:

### Option 1: Use ScreenCaptureKit
Instead of a camera extension, capture your camera window:

```swift
// Use ScreenCaptureKit to capture a window showing camera feed
// This doesn't require system extensions
```

### Option 2: Create a Simple Virtual Camera Test
Use AVFoundation with a local loopback:

```swift
// Create a virtual camera using AVCaptureScreenInput
// Present it as a window that can be captured
```

### Option 3: Direct Integration
Skip the virtual camera and integrate directly with your app:

```swift
// Use Aravis directly in your app
// Stream to LiveKit without virtual camera
```

## Current Status

The system extension requires:
1. ✅ Proper code structure (done)
2. ✅ Entitlements files (done)
3. ❌ Provisioning profiles with System Extension capability
4. ❌ Notarization for distribution

Without these, you'll get error code 1 when trying to install.