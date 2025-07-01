#!/bin/bash

# Sign GigE Virtual Camera for local testing with SIP disabled
# This creates a proper ad-hoc signature for testing

echo "=== Signing GigE Virtual Camera for Local Testing ==="
echo

APP_PATH="/Applications/GigEVirtualCamera.app"
EXTENSION_PATH="$APP_PATH/Contents/Library/SystemExtensions/GigECameraExtension.systemextension"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at $APP_PATH"
    exit 1
fi

echo "1. Removing old signatures..."
rm -rf "$APP_PATH/Contents/_CodeSignature"
rm -rf "$EXTENSION_PATH/Contents/_CodeSignature"
rm -f "$APP_PATH/Contents/embedded.provisionprofile"
rm -f "$EXTENSION_PATH/Contents/embedded.provisionprofile"

echo "2. Signing system extension..."
codesign --force --deep --sign - \
    --entitlements /dev/null \
    "$EXTENSION_PATH"

echo "3. Signing main app..."
codesign --force --deep --sign - \
    --entitlements /dev/null \
    "$APP_PATH"

echo "4. Verifying signatures..."
echo "   App:"
codesign --verify --verbose "$APP_PATH"
echo "   Extension:"
codesign --verify --verbose "$EXTENSION_PATH"

echo
echo "✅ Signing complete!"
echo
echo "Now you can:"
echo "1. Launch the app: open $APP_PATH"
echo "2. Click 'Install Extension' in the app"
echo "3. If prompted, approve in System Settings > Privacy & Security"