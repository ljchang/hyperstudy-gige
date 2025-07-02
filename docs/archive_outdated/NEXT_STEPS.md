# Next Steps to Enable System Extension

You've updated the certificate! Now you need to:

## 1. Create App IDs in Apple Developer Portal

Go to: https://developer.apple.com/account/resources/identifiers/list

### Main App ID:
- Bundle ID: `com.lukechang.GigEVirtualCamera`
- Enable capabilities:
  - **System Extension** ✓ (Required for installing system extensions)
  - **App Groups** ✓ (For shared data between app and extension)
  - **Network** → Outgoing Connections (Client) ✓ (For GigE camera network access)

### Extension App ID:
- Bundle ID: `com.lukechang.GigEVirtualCamera.Extension`
- Enable capabilities:
  - **App Groups** ✓ (Same group as main app: group.com.lukechang.gigecamera)
  - **Camera Extension** ✓ (If available - this identifies it as a CMIO extension)

## 2. Create Provisioning Profiles

Go to: https://developer.apple.com/account/resources/profiles/list

### For Development:

#### Main App Profile:
- Type: **macOS App Development**
- App ID: com.lukechang.GigEVirtualCamera
- Certificate: Apple Development (6696TSCXZY)
- Name: "GigE Virtual Camera Dev"

#### Extension Profile:
- Type: **macOS App Development**
- App ID: com.lukechang.GigEVirtualCamera.Extension
- Certificate: Apple Development (6696TSCXZY)
- Name: "GigE Camera Extension Dev"

### For Distribution (Required for System Extensions):

#### Main App Profile:
- Type: **Developer ID Application**
- App ID: com.lukechang.GigEVirtualCamera
- Certificate: Developer ID Application (create if needed)
- Name: "GigE Virtual Camera Distribution"

#### Extension Profile:
- Type: **Developer ID Application**
- App ID: com.lukechang.GigEVirtualCamera.Extension
- Certificate: Developer ID Application (same as above)
- Name: "GigE Camera Extension Distribution"

**Note:** System Extensions require Developer ID signing for distribution outside the Mac App Store.

## 3. Download and Install Profiles

1. Download both .provisionprofile files
2. Double-click each to install in Xcode

## 4. Build and Test

```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*

# Open Xcode
open /Users/lukechang/Github/hyperstudy-gige/macos/GigEVirtualCamera.xcodeproj
```

In Xcode:
1. Product → Clean Build Folder
2. Product → Build
3. Product → Run

The system extension should now install successfully!

## Quick Check

Your certificate is ready:
- Certificate ID: 6696TSCXZY
- Team ID: S368GH6KF7
- Type: Apple Development

Once you create the App IDs and provisioning profiles in the Apple Developer portal, the system extension will work.

## Important Notes on Capabilities:

1. **System Extension capability** is MANDATORY for the main app - without it, the app cannot install system extensions

2. **App Groups** must use the same group identifier in both targets:
   - Format: `group.com.lukechang.gigecamera`
   - Must match exactly in both app and extension entitlements

3. **Network capability** is only needed on the main app (not the extension) since only the app communicates with GigE cameras

4. **Camera capability** is NOT needed on either target because:
   - The app gets video from GigE cameras via network (Aravis), not system cameras
   - The extension receives frames from the app, not from hardware cameras

5. **For Distribution**: You'll need a Developer ID certificate (not just Apple Development) because System Extensions cannot be distributed with ad-hoc or development signing