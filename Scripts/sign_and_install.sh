#!/bin/bash

# Script to properly sign and install GigE Virtual Camera after Xcode build
# This ensures all components are signed correctly for system extension installation

set -e

echo "=== GigE Virtual Camera Sign & Install ==="
echo

# Find the most recent build in DerivedData
DERIVED_DATA_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "GigEVirtualCamera.app" -path "*/Build/Products/Debug/*" -type d 2>/dev/null | head -1)

if [ -z "$DERIVED_DATA_PATH" ]; then
    echo "❌ Error: Could not find built app in DerivedData"
    echo "Please build the app in Xcode first"
    exit 1
fi

echo "Found app at: $DERIVED_DATA_PATH"

# Create a temporary copy to work with
TEMP_APP="/tmp/GigEVirtualCamera.app"
echo "Creating temporary copy..."
rm -rf "$TEMP_APP" 2>/dev/null || true
ditto "$DERIVED_DATA_PATH" "$TEMP_APP"

# Find signing identity
IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | awk '{print $2}')
if [ -z "$IDENTITY" ]; then
    echo "❌ Error: No Apple Development certificate found"
    exit 1
fi
echo "Using signing identity: $IDENTITY"

# 1. Sign all embedded libraries
echo
echo "1. Signing embedded libraries..."
find "$TEMP_APP/Contents/Frameworks" -name "*.dylib" -type f | while read lib; do
    echo "  Signing: $(basename "$lib")"
    codesign --force --sign "$IDENTITY" --timestamp=none "$lib"
done

# 2. Sign the system extension
echo
echo "2. Signing system extension..."
EXTENSION_PATH="$TEMP_APP/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
if [ -d "$EXTENSION_PATH" ]; then
    codesign --force --deep --sign "$IDENTITY" \
        --entitlements "/Users/lukechang/Github/hyperstudy-gige/GigEVirtualCameraExtension/GigEVirtualCameraExtension.entitlements" \
        --timestamp=none \
        "$EXTENSION_PATH"
    echo "  ✓ Extension signed"
else
    echo "  ❌ Extension not found!"
fi

# 3. Sign the main app
echo
echo "3. Signing main app..."
codesign --force --deep --sign "$IDENTITY" \
    --entitlements "/Users/lukechang/Github/hyperstudy-gige/GigECameraApp/GigECamera-Debug.entitlements" \
    --options runtime \
    --timestamp=none \
    "$TEMP_APP"

# 4. Verify signatures
echo
echo "4. Verifying signatures..."
if codesign --verify --deep --strict "$TEMP_APP" 2>&1; then
    echo "  ✓ App signature valid"
else
    echo "  ❌ App signature invalid!"
    exit 1
fi

# 5. Install to /Applications
echo
echo "5. Installing to /Applications..."
sudo rm -rf "/Applications/GigEVirtualCamera.app" 2>/dev/null || true
sudo ditto "$TEMP_APP" "/Applications/GigEVirtualCamera.app"

# 6. Reset system extension daemon
echo
echo "6. Resetting system extension daemon..."
sudo killall -9 sysextd 2>/dev/null || true

# Clean up
rm -rf "$TEMP_APP"

echo
echo "✅ Success! GigE Virtual Camera is signed and installed."
echo
echo "Next steps:"
echo "1. Open /Applications/GigEVirtualCamera.app"
echo "2. Click 'Install Extension'"
echo "3. Approve in System Settings > Privacy & Security if prompted"