#!/bin/bash

echo "=== Clean and Verify Signing ==="
echo

# 1. Check current state
echo "1. Current extension signing status:"
codesign -dvvv /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep -E "Format=|Signature|Identifier|TeamIdentifier" | head -10

# 2. Strip extended attributes that might interfere with signing
echo
echo "2. Removing extended attributes..."
xattr -cr /Applications/GigEVirtualCamera.app

# 3. Re-sign everything properly
echo
echo "3. Re-signing app and extension..."

# Find the right identity
IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | awk '{print $2}')
if [ -z "$IDENTITY" ]; then
    echo "❌ No Apple Development certificate found"
    exit 1
fi

echo "Using identity: $IDENTITY"

# Sign all frameworks/libraries
echo "Signing libraries..."
find /Applications/GigEVirtualCamera.app/Contents/Frameworks -name "*.dylib" -type f | while read lib; do
    codesign --force --sign "$IDENTITY" --timestamp=none "$lib"
done

# Sign the extension with proper entitlements
echo "Signing extension..."
codesign --force --deep --sign "$IDENTITY" \
    --entitlements /Users/lukechang/Github/hyperstudy-gige/GigEVirtualCameraExtension/GigEVirtualCameraExtension.entitlements \
    --timestamp=none \
    /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension

# Sign the main app
echo "Signing main app..."
codesign --force --deep --sign "$IDENTITY" \
    --entitlements /Users/lukechang/Github/hyperstudy-gige/GigECameraApp/GigECamera-Debug.entitlements \
    --options runtime \
    --timestamp=none \
    /Applications/GigEVirtualCamera.app

# 4. Verify signatures
echo
echo "4. Verifying signatures..."
echo "App:"
codesign -vvv --deep --strict /Applications/GigEVirtualCamera.app 2>&1 | grep -E "valid|satisfies|error" || echo "✓ App signature valid"

echo
echo "Extension:"
codesign -vvv --deep --strict /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep -E "valid|satisfies|error" || echo "✓ Extension signature valid"

# 5. Check final state
echo
echo "5. Final extension info:"
codesign -dvvv /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep -E "Format=|Signature|Identifier|TeamIdentifier"

echo
echo "6. Reset system extensions database:"
echo "Run: systemextensionsctl reset"
echo "Then try installing the extension again"