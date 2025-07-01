#!/bin/bash

# Quick fix for code signing after Xcode build
# Run this if you get "Invalid code signature" errors

echo "=== Fixing Code Signing ==="

# Check if app exists in /Applications
if [ ! -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "❌ App not found in /Applications"
    echo "Build in Xcode first!"
    exit 1
fi

# Find signing identity
IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | awk '{print $2}')
if [ -z "$IDENTITY" ]; then
    echo "❌ No Apple Development certificate found"
    exit 1
fi

echo "Using identity: $IDENTITY"

# Fix extension folder name if needed
if [ -d "/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension" ]; then
    echo "Renaming extension folder to match bundle ID..."
    mv /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension \
       /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension
fi

# Sign all dynamic libraries
echo "Signing libraries..."
find /Applications/GigEVirtualCamera.app/Contents/Frameworks -name "*.dylib" | while read lib; do
    codesign --force --sign "$IDENTITY" --timestamp=none "$lib" 2>/dev/null
done

# Create temporary entitlements for extension
TEMP_EXT_ENTITLEMENTS="/tmp/expanded-ext-entitlements.plist"
sed 's/$(TeamIdentifierPrefix)/S368GH6KF7./g' /Users/lukechang/Github/hyperstudy-gige/GigEVirtualCameraExtension/GigEVirtualCameraExtension.entitlements > "$TEMP_EXT_ENTITLEMENTS"

# Sign the extension
echo "Signing extension..."
codesign --force --deep --sign "$IDENTITY" \
    --entitlements "$TEMP_EXT_ENTITLEMENTS" \
    --timestamp=none \
    /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension

# Clean up
rm -f "$TEMP_EXT_ENTITLEMENTS"

# Create temporary entitlements with expanded values
TEMP_ENTITLEMENTS="/tmp/expanded-entitlements.plist"
sed 's/$(TeamIdentifierPrefix)/S368GH6KF7./g' /Users/lukechang/Github/hyperstudy-gige/GigECameraApp/GigECamera-Debug.entitlements > "$TEMP_ENTITLEMENTS"

# Sign the main app
echo "Signing app..."
codesign --force --deep --sign "$IDENTITY" \
    --entitlements "$TEMP_ENTITLEMENTS" \
    --options runtime \
    --timestamp=none \
    /Applications/GigEVirtualCamera.app

# Clean up
rm -f "$TEMP_ENTITLEMENTS"

# Verify
if codesign --verify --deep /Applications/GigEVirtualCamera.app 2>&1; then
    echo "✅ Signing fixed!"
else
    echo "❌ Signing still broken"
fi