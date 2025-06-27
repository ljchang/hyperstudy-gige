#!/bin/bash

# Notarize the GigE Virtual Camera app

set -e

# Configuration
APP_PATH="${1:-/Applications/GigEVirtualCamera.app}"
BUNDLE_ID="com.lukechang.GigEVirtualCamera"
TEAM_ID="S368GH6KF7"
ZIP_PATH="GigEVirtualCamera.zip"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    echo "Usage: $0 [app_path]"
    exit 1
fi

echo "=== Notarizing GigE Virtual Camera ==="
echo "App: $APP_PATH"

# 1. Create a zip for notarization
echo -e "\n1. Creating zip archive..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "Created: $ZIP_PATH ($(du -h "$ZIP_PATH" | cut -f1))"

# 2. Submit for notarization
echo -e "\n2. Submitting for notarization..."
echo "This will prompt for your Apple ID credentials."
echo "You'll need an app-specific password from https://appleid.apple.com"

xcrun notarytool submit "$ZIP_PATH" \
    --team-id "$TEAM_ID" \
    --wait \
    --verbose

# 3. Check status
echo -e "\n3. Checking notarization status..."
# The status is shown by --wait above

# 4. Staple the ticket
echo -e "\n4. Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

# 5. Verify
echo -e "\n5. Verifying notarization..."
spctl -a -vvv -t install "$APP_PATH"

# 6. Clean up
echo -e "\n6. Cleaning up..."
rm -f "$ZIP_PATH"

echo -e "\n✅ Notarization complete!"
echo -e "\nThe app at $APP_PATH is now notarized and ready for distribution."
echo -e "\nTo test:"
echo "1. Move the app to a different Mac"
echo "2. Double-click to open - it should open without security warnings"
echo "3. The virtual camera should appear in camera-enabled apps"