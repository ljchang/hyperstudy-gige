# Notarization Guide for GigE Virtual Camera

## Prerequisites

1. Go to https://appleid.apple.com/account/manage
2. Sign in with your Apple Developer account
3. Under "Security", click "Generate Password..."
4. Enter a label like "GigE Camera Notarization"
5. Save the password securely (you'll need it for notarytool)

## Option 1: Using App-Specific Password

### Step 1: Store credentials in keychain
```bash
xcrun notarytool store-credentials "GigE-Notarization" \
    --apple-id "your-apple-id@example.com" \
    --team-id "S368GH6KF7" \
    --password "your-app-specific-password"
```

### Step 2: Create archive for notarization
```bash
# Clean any existing archives
rm -f GigEVirtualCamera.zip

# Create a zip archive (must use ditto to preserve structure)
ditto -c -k --keepParent /Applications/GigEVirtualCamera.app GigEVirtualCamera.zip
```

### Step 3: Submit for notarization
```bash
xcrun notarytool submit GigEVirtualCamera.zip \
    --keychain-profile "GigE-Notarization" \
    --wait
```

### Step 4: Check status (if needed)
```bash
# If you didn't use --wait, check status with the ID returned
xcrun notarytool info <submission-id> \
    --keychain-profile "GigE-Notarization"

# Get detailed log if there are issues
xcrun notarytool log <submission-id> \
    --keychain-profile "GigE-Notarization" \
    developer_log.json
```

### Step 5: Staple the ticket
```bash
# Once notarized, staple the ticket to the app
xcrun stapler staple /Applications/GigEVirtualCamera.app

# Verify stapling worked
xcrun stapler validate /Applications/GigEVirtualCamera.app
```

## Option 2: Using API Key (Recommended for CI/CD)

### Step 1: Create API Key
1. Go to https://appstoreconnect.apple.com/access/api
2. Click the "+" button to create a new key
3. Name: "GigE Camera Notarization"
4. Access: "Developer"
5. Download the .p8 file (you can only download once!)

### Step 2: Use API key for notarization
```bash
xcrun notarytool submit GigEVirtualCamera.zip \
    --key /path/to/AuthKey_XXXXXXXXXX.p8 \
    --key-id "XXXXXXXXXX" \
    --issuer "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" \
    --wait
```

## Common Requirements for Successful Notarization

1. **Code Signing**:
   - All executables must be signed with Developer ID
   - Use hardened runtime (--options runtime)
   - Include secure timestamp (--timestamp)

2. **Entitlements**:
   - Only use allowed entitlements
   - Hardened runtime exceptions need justification

3. **No deprecated APIs**:
   - Remove usage of deprecated technologies
   - No 32-bit code

4. **Info.plist**:
   - Must have proper bundle identifier
   - Version numbers must be set

## Troubleshooting

### If notarization fails:

1. **Check the log**:
   ```bash
   xcrun notarytool log <submission-id> --keychain-profile "GigE-Notarization" log.json
   cat log.json | jq '.issues'
   ```

2. **Common issues**:
   - Missing hardened runtime
   - Unsigned nested code
   - Invalid entitlements
   - Unsigned frameworks/libraries

3. **Fix signing issues**:
   ```bash
   # Re-sign with proper options
   codesign --force --deep --sign "Developer ID Application: Luke  Chang (S368GH6KF7)" \
            --options runtime --timestamp \
            /Applications/GigEVirtualCamera.app
   ```

## Automation Script

Create `Scripts/notarize.sh`:

```bash
#!/bin/bash
set -e

APP_PATH="${1:-/Applications/GigEVirtualCamera.app}"
PROFILE_NAME="GigE-Notarization"

echo "📦 Creating archive..."
rm -f GigEVirtualCamera.zip
ditto -c -k --keepParent "$APP_PATH" GigEVirtualCamera.zip

echo "📤 Submitting for notarization..."
SUBMISSION_ID=$(xcrun notarytool submit GigEVirtualCamera.zip \
    --keychain-profile "$PROFILE_NAME" \
    --wait \
    --output-format json | jq -r '.id')

echo "✅ Notarization complete!"

echo "📎 Stapling ticket..."
xcrun stapler staple "$APP_PATH"

echo "🎉 Success! App is notarized and ready for distribution"
rm -f GigEVirtualCamera.zip
```

## Distribution

After notarization, you can:
1. Create a DMG for distribution
2. Upload to your website
3. Users can download and run without Gatekeeper warnings

The notarized app will:
- Pass Gatekeeper checks
- Load all extensions properly
- Show as "Verified" in security prompts