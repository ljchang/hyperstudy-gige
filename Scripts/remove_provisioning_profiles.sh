#!/bin/bash

# remove_provisioning_profiles.sh - Remove provisioning profiles for local testing
# This allows the app to run without Developer ID profiles, but only on the development machine

set -e

APP_PATH="/Applications/GigEVirtualCamera.app"
EXTENSION_PATH="$APP_PATH/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"

echo "Removing provisioning profiles for local testing..."

# Remove profiles
rm -f "$APP_PATH/Contents/embedded.provisionprofile"
rm -f "$EXTENSION_PATH/Contents/embedded.provisionprofile"

# Re-sign with local identity (not Developer ID)
echo "Re-signing with local identity..."

# Sign extension
codesign --force --deep --sign - "$EXTENSION_PATH"

# Sign app
codesign --force --deep --sign - "$APP_PATH"

echo "Done! The app should now run locally."
echo ""
echo "⚠️  WARNING: This app will NOT work on other machines!"
echo "For distribution, you need proper Developer ID provisioning profiles."