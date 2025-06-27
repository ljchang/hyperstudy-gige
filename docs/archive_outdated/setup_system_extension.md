# Setting Up System Extension with New Certificate

## Step 1: Create App IDs (if not already done)

Go to https://developer.apple.com/account/resources/identifiers/list

1. **Main App ID**:
   - Click "+" to create new identifier
   - Select "App IDs" → Continue
   - Select "App" → Continue
   - Description: "GigE Virtual Camera"
   - Bundle ID: `com.lukechang.GigEVirtualCamera`
   - Capabilities: Enable "System Extension"
   - Register

2. **Extension App ID**:
   - Click "+" again
   - Select "App IDs" → Continue
   - Select "App" → Continue
   - Description: "GigE Camera Extension"
   - Bundle ID: `com.lukechang.GigEVirtualCamera.Extension`
   - Capabilities: Enable "Camera Extension"
   - Register

## Step 2: Create Provisioning Profiles

Go to https://developer.apple.com/account/resources/profiles/list

1. **Main App Profile**:
   - Click "+"
   - Select "macOS App Development" → Continue
   - Select App ID: "GigE Virtual Camera" → Continue
   - Select Certificate: Your new certificate → Continue
   - Name: "GigE Virtual Camera Dev" → Generate
   - Download

2. **Extension Profile**:
   - Click "+"
   - Select "macOS App Development" → Continue
   - Select App ID: "GigE Camera Extension" → Continue
   - Select Certificate: Your new certificate → Continue
   - Name: "GigE Camera Extension Dev" → Generate
   - Download

## Step 3: Install Profiles

Double-click each downloaded .provisionprofile file to install in Xcode.

## Step 4: Update Xcode Project

1. Open the project in Xcode
2. Select the project in navigator
3. For EACH target (app and extension):
   - Go to "Signing & Capabilities"
   - Uncheck "Automatically manage signing"
   - Team: Luke Chang (S368GH6KF7)
   - Provisioning Profile: Select the appropriate profile
   - Signing Certificate: Select your certificate

## Step 5: Clean and Rebuild

```bash
cd /Users/lukechang/Github/hyperstudy-gige/macos
rm -rf ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*
xcodebuild clean
```

Then rebuild in Xcode.