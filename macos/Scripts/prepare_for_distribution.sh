#!/bin/bash

# Prepare GigE Virtual Camera for distribution
# This script handles code signing and prepares for notarization

set -e

# Configuration
APP_PATH="${1:-/Users/lukechang/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*/Build/Products/Debug/GigEVirtualCamera.app}"
APP_PATH=$(ls -d $APP_PATH 2>/dev/null | head -1)

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    echo "Usage: $0 [app_path]"
    exit 1
fi

IDENTITY="${CODESIGN_IDENTITY:-Apple Development}"
TEAM_ID="S368GH6KF7"

echo "Preparing app for distribution: $APP_PATH"

# Function to sign a binary
sign_binary() {
    local binary_path="$1"
    local identifier="$2"
    
    echo "Signing: $(basename "$binary_path")"
    
    # Remove existing signature
    codesign --remove-signature "$binary_path" 2>/dev/null || true
    
    # Sign with hardened runtime and timestamp
    codesign --force \
             --sign "$IDENTITY" \
             --identifier "$identifier" \
             --options runtime \
             --timestamp \
             --verbose \
             "$binary_path"
}

# 1. Sign all bundled libraries
echo -e "\n1. Signing bundled libraries..."

# Sign frameworks in main app
for lib in "$APP_PATH/Contents/Frameworks"/*.dylib; do
    if [ -f "$lib" ]; then
        lib_name=$(basename "$lib" .dylib)
        sign_binary "$lib" "org.aravis.$lib_name"
    fi
done

# Sign frameworks in extension
EXTENSION_PATH="$APP_PATH/Contents/PlugIns/GigECameraExtension.appex"
for lib in "$EXTENSION_PATH/Contents/Frameworks"/*.dylib; do
    if [ -f "$lib" ]; then
        lib_name=$(basename "$lib" .dylib)
        sign_binary "$lib" "org.aravis.$lib_name"
    fi
done

# 2. Sign the extension
echo -e "\n2. Signing camera extension..."

# First sign the debug dylib if it exists
if [ -f "$EXTENSION_PATH/Contents/MacOS/GigECameraExtension.debug.dylib" ]; then
    sign_binary "$EXTENSION_PATH/Contents/MacOS/GigECameraExtension.debug.dylib" \
                "com.lukechang.GigEVirtualCamera.Extension.debug"
fi

# Sign the extension bundle
codesign --force \
         --sign "$IDENTITY" \
         --entitlements "$EXTENSION_PATH/../../GigECameraExtension/GigECameraExtension.entitlements" \
         --options runtime \
         --timestamp \
         --verbose \
         "$EXTENSION_PATH"

# 3. Sign the main app
echo -e "\n3. Signing main app..."

# Sign the main app debug dylib if it exists
if [ -f "$APP_PATH/Contents/MacOS/GigEVirtualCamera.debug.dylib" ]; then
    sign_binary "$APP_PATH/Contents/MacOS/GigEVirtualCamera.debug.dylib" \
                "com.lukechang.GigEVirtualCamera.debug"
fi

# Sign the main app
codesign --force \
         --sign "$IDENTITY" \
         --entitlements "$APP_PATH/../../GigECameraApp/GigECamera.entitlements" \
         --options runtime \
         --timestamp \
         --deep \
         --verbose \
         "$APP_PATH"

# 4. Verify signatures
echo -e "\n4. Verifying signatures..."

echo "Main app:"
codesign --verify --verbose "$APP_PATH"
spctl --assess --verbose "$APP_PATH" 2>&1 || echo "Note: Gatekeeper check failed (expected for development builds)"

echo -e "\nExtension:"
codesign --verify --verbose "$EXTENSION_PATH"

# 5. Check entitlements
echo -e "\n5. Checking entitlements..."

echo "Main app entitlements:"
codesign -d --entitlements :- "$APP_PATH" 2>&1 | grep -A20 "<?xml" | grep -E "(camera|extension|sandbox)" || true

echo -e "\nExtension entitlements:"
codesign -d --entitlements :- "$EXTENSION_PATH" 2>&1 | grep -A20 "<?xml" | grep -E "(camera|mach-service|sandbox)" || true

echo -e "\n✅ App is signed and ready for notarization!"
echo -e "\nNext steps:"
echo "1. Archive the app: ditto -c -k --keepParent \"$APP_PATH\" \"GigEVirtualCamera.zip\""
echo "2. Submit for notarization: xcrun notarytool submit GigEVirtualCamera.zip --team-id $TEAM_ID --wait"
echo "3. Staple the ticket: xcrun stapler staple \"$APP_PATH\""