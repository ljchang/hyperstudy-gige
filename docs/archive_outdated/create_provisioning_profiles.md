# Creating Provisioning Profiles for GigE Virtual Camera

## Prerequisites
- Apple Developer account
- Access to developer.apple.com

## Step 1: Register App IDs (if not already done)

### Main App ID
1. Go to https://developer.apple.com/account/resources/identifiers/list
2. Click "+" to add a new identifier
3. Select "App IDs" and click Continue
4. Select "App" and click Continue
5. Fill in:
   - Description: GigE Virtual Camera
   - Bundle ID: Explicit - `com.lukechang.GigEVirtualCamera`
   - Capabilities: 
     - System Extension (under Additional Capabilities)
     - Camera (if available)
6. Click Continue and Register

### Extension App ID
1. Click "+" to add another identifier
2. Select "App IDs" and click Continue
3. Select "App" and click Continue
4. Fill in:
   - Description: GigE Camera Extension
   - Bundle ID: Explicit - `com.lukechang.GigEVirtualCamera.Extension`
   - Capabilities:
     - Camera Extension (if available)
     - System Extension (under Additional Capabilities)
5. Click Continue and Register

## Step 2: Create Provisioning Profiles

### Development Profiles (for testing)

#### Main App Development Profile
1. Go to https://developer.apple.com/account/resources/profiles/list
2. Click "+" to create a new profile
3. Select "macOS App Development" and click Continue
4. Select App ID: `com.lukechang.GigEVirtualCamera`
5. Select your development certificate
6. Select your Mac devices
7. Name it: "GigE Virtual Camera Dev"
8. Generate and download

#### Extension Development Profile
1. Click "+" to create another profile
2. Select "macOS App Development" and click Continue
3. Select App ID: `com.lukechang.GigEVirtualCamera.Extension`
4. Select your development certificate
5. Select your Mac devices
6. Name it: "GigE Camera Extension Dev"
7. Generate and download

### Distribution Profiles (for release)

#### Main App Distribution Profile
1. Click "+" to create a new profile
2. Select "Developer ID" and click Continue
3. Select App ID: `com.lukechang.GigEVirtualCamera`
4. Select your Developer ID certificate
5. Name it: "GigE Virtual Camera Distribution"
6. Generate and download

#### Extension Distribution Profile
1. Click "+" to create another profile
2. Select "Developer ID" and click Continue
3. Select App ID: `com.lukechang.GigEVirtualCamera.Extension`
4. Select your Developer ID certificate
5. Name it: "GigE Camera Extension Distribution"
6. Generate and download

## Step 3: Install Provisioning Profiles

1. Double-click each downloaded `.provisionprofile` file to install
2. Or manually copy to: `~/Library/MobileDevice/Provisioning Profiles/`

## Step 4: Configure Xcode

1. Open your project in Xcode
2. Select the main app target
3. Go to "Signing & Capabilities"
4. Ensure "Automatically manage signing" is OFF
5. Select the appropriate provisioning profile
6. Repeat for the extension target

## Important Notes

- The main app MUST have the `com.apple.developer.system-extension.install` entitlement
- The extension should be signed with the same Developer ID as the main app
- For distribution outside the App Store, use Developer ID certificates
- System extensions require notarization for distribution

## Verification

After creating and installing the profiles, verify they contain the correct entitlements:

```bash
# Check app provisioning profile
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/[UUID].mobileprovision | grep -A 20 Entitlements

# The app profile should contain:
# <key>com.apple.developer.system-extension.install</key>
# <true/>
```