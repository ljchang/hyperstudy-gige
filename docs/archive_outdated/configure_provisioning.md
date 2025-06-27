# Configure Provisioning Profile in Xcode

The new provisioning profile with system extension entitlements has been downloaded but Xcode is still using the old one.

## Steps to Fix:

1. **In Xcode (now open):**
   - Select the **GigECameraExtension** target
   - Go to "Signing & Capabilities" tab
   - Under "Signing", ensure "Automatically manage signing" is OFF
   - In "Provisioning Profile" dropdown, select "GigE Camera Extension Dev" 
   - The UUID should be: `8b8b81bc-bdf5-4600-99e3-1594ddd640d3`

2. **Alternative: Force specific profile in build settings:**
   - Select the extension target
   - Go to "Build Settings" tab
   - Search for "PROVISIONING_PROFILE_SPECIFIER"
   - Set it to: `GigE Camera Extension Dev`

3. **Clean and rebuild:**
   ```bash
   # After updating in Xcode, run:
   xcodebuild clean build -project GigEVirtualCamera.xcodeproj -scheme GigEVirtualCamera
   ```

## Verification:
After rebuilding, the extension's embedded profile should show:
```xml
<key>com.apple.developer.system-extension.install</key>
<true/>
```

This is the key entitlement that was missing!