# Next Steps to Enable System Extension

You've updated the certificate! Now you need to:

## 1. Create App IDs in Apple Developer Portal

Go to: https://developer.apple.com/account/resources/identifiers/list

### Main App ID:
- Bundle ID: `com.lukechang.GigEVirtualCamera`
- Enable capability: **System Extension** ✓

### Extension App ID:
- Bundle ID: `com.lukechang.GigEVirtualCamera.Extension`
- No special capabilities needed for camera extension

## 2. Create Provisioning Profiles

Go to: https://developer.apple.com/account/resources/profiles/list

### Main App Profile:
- Type: macOS App Development
- App ID: com.lukechang.GigEVirtualCamera
- Certificate: Apple Development (6696TSCXZY)
- Name: "GigE Virtual Camera Dev"

### Extension Profile:
- Type: macOS App Development
- App ID: com.lukechang.GigEVirtualCamera.Extension
- Certificate: Apple Development (6696TSCXZY)
- Name: "GigE Camera Extension Dev"

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