#!/bin/bash

# Sign app with Developer ID certificate after building without code signing

set -e

APP_PATH="${1:-/Users/lukechang/Github/hyperstudy-gige/build/Release/GigEVirtualCamera.app}"
IDENTITY="Developer ID Application: Luke  Chang (S368GH6KF7)"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

echo "Signing app with Developer ID certificate..."

# 1. Sign all frameworks
echo "1. Signing frameworks..."
for framework in "$APP_PATH/Contents/Frameworks"/*.dylib; do
    if [ -f "$framework" ]; then
        echo "  Signing: $(basename "$framework")"
        codesign --force --sign "$IDENTITY" --timestamp --options runtime "$framework"
    fi
done

# 2. Sign the extension
EXTENSION_PATH="$APP_PATH/Contents/PlugIns/GigECameraExtension.appex"
if [ -d "$EXTENSION_PATH" ]; then
    echo "2. Signing extension..."
    codesign --force --sign "$IDENTITY" \
             --entitlements GigECameraExtension/GigECameraExtension-Release.entitlements \
             --timestamp --options runtime \
             "$EXTENSION_PATH"
fi

# 3. Sign the main app
echo "3. Signing main app..."
codesign --force --sign "$IDENTITY" \
         --entitlements GigECameraApp/GigECamera-Release.entitlements \
         --timestamp --options runtime \
         "$APP_PATH"

# 4. Verify
echo "4. Verifying signatures..."
codesign --verify --verbose "$APP_PATH"
spctl -a -v "$APP_PATH"

echo "✅ App signed with Developer ID certificate"