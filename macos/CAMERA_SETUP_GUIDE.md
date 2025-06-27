# GigE Virtual Camera - Setup Guide

## Prerequisites

1. **macOS 12.3 or later** (required for CMIO extensions)
2. **Apple Developer Account** (for code signing and notarization)
3. **GigE Vision camera** connected to your network

## Step-by-Step Setup

### 1. Build Release Version

```bash
cd /Users/lukechang/Github/hyperstudy-gige/macos
./Scripts/build_release.sh
```

This will:
- Build a Release configuration
- Sign all components
- Install to `/Applications`
- Reset the camera subsystem

### 2. First Launch

1. Open `/Applications/GigEVirtualCamera.app`
2. macOS may show a security prompt - click "Open" 
3. Go to **System Settings > Privacy & Security > Camera**
4. Make sure GigEVirtualCamera has permission

### 3. For Distribution (Notarization)

If you need to distribute the app to other Macs:

```bash
./Scripts/notarize_app.sh /Applications/GigEVirtualCamera.app
```

You'll need:
- Your Apple ID
- An app-specific password from https://appleid.apple.com
- To wait 5-10 minutes for Apple to process

### 4. Troubleshooting

#### Camera Not Appearing

1. **Check diagnostics:**
   ```bash
   ./Scripts/diagnose_camera.sh
   ```

2. **Reset camera system:**
   ```bash
   sudo killall -9 cmioextension
   rm -rf ~/Library/Caches/com.apple.cmio*
   # Then restart your Mac
   ```

3. **Verify in Console app:**
   - Open Console.app
   - Search for "GigE" or "cmio"
   - Look for any error messages

4. **Test in different apps:**
   - Photo Booth (simplest test)
   - QuickTime Player > File > New Movie Recording
   - FaceTime
   - Zoom/Teams/etc.

#### Common Issues

**"App is damaged"**
- The app needs to be notarized
- Run the notarization script

**Camera doesn't appear after install**
- Restart your Mac (sometimes required for first CMIO extension)
- Make sure no other virtual camera software is conflicting

**Extension not loading**
- Check Console.app for sandbox violations
- Ensure all entitlements are correct
- Try running from `/Applications` not Xcode

### 5. Using the Camera

Once properly installed:

1. **Connect your GigE camera** to the network
2. **Launch GigEVirtualCamera app**
3. The app will automatically discover cameras
4. **Open any camera app** (Photo Booth, Zoom, etc.)
5. **Select "GigE Virtual Camera"** from the camera list

### 6. Development vs Production

**Development Build (from Xcode):**
- May not register properly as a camera
- Good for testing Aravis integration
- Run from Xcode for debugging

**Release Build (from script):**
- Properly signed and registered
- Camera appears in all apps
- Ready for distribution after notarization

## Technical Details

### Why Camera May Not Appear

1. **Security Requirements:**
   - CMIO extensions must be properly signed
   - Hardened runtime is required
   - Specific entitlements needed

2. **Registration Process:**
   - Extension must call `addDevice()` during initialization
   - Must be in `/Applications` or system folders
   - System caches the extension list

3. **Notarization:**
   - Required for distribution to other Macs
   - Prevents "app is damaged" errors
   - Takes 5-10 minutes to process

### Architecture

```
GigEVirtualCamera.app
├── Contents/
│   ├── MacOS/
│   │   └── GigEVirtualCamera (main app)
│   ├── PlugIns/
│   │   └── GigECameraExtension.appex (CMIO extension)
│   └── Frameworks/
│       └── libaravis-0.8.0.dylib (+ dependencies)
```

The CMIO extension runs in a separate process and provides the virtual camera to the system.