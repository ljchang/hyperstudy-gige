# Fix Provisioning Profiles for System Extension

## The Issue
The extension's provisioning profile is missing required entitlements. For a CMIOExtension (Camera Extension), the provisioning profile needs specific capabilities.

## Steps to Fix

### 1. Update App ID for Extension
Go to https://developer.apple.com/account/resources/identifiers/list

1. Find `com.lukechang.GigEVirtualCamera.Extension`
2. Click on it to edit
3. Under "Capabilities", ensure these are checked:
   - **System Extension** (under Additional Capabilities)
   - **Camera** (if available)
   - **App Groups** (if using group.com.lukechang.gigecamera)
4. Save changes

### 2. Regenerate Extension Provisioning Profile
Go to https://developer.apple.com/account/resources/profiles/list

1. Find "GigE Camera Extension Dev" profile
2. Click "Edit" 
3. Verify it shows the updated capabilities
4. Click "Save" to regenerate
5. Download the new profile
6. Double-click to install

### 3. Clean Build and Test
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*

# Open Xcode and verify provisioning profiles
open GigEVirtualCamera.xcodeproj

# In Xcode:
# 1. Select extension target
# 2. Go to Signing & Capabilities
# 3. Re-select the provisioning profile
# 4. Build and run
```

### 4. Alternative: Manual Signing
If automatic profile selection doesn't work:

1. In Xcode, select the extension target
2. Go to "Build Settings"
3. Search for "CODE_SIGN_STYLE"
4. Change from "Automatic" to "Manual"
5. Set PROVISIONING_PROFILE_SPECIFIER to "GigE Camera Extension Dev"
6. Build

## Verification
After installing the new profile, verify it has the correct entitlements:

```bash
# Find the new profile UUID
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Check its entitlements
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/[UUID].mobileprovision | grep -A 50 Entitlements
```

The extension profile should now include system extension related entitlements.