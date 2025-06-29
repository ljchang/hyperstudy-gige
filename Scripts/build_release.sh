#!/bin/bash

# Build release version of GigE Virtual Camera with proper signing

set -e

echo "=== Building GigE Virtual Camera Release ==="

# 1. Clean and generate project
echo "1. Cleaning and generating project..."
cd /Users/lukechang/Github/hyperstudy-gige
xcodegen generate

# 2. Clean build folder
echo -e "\n2. Cleaning build folder..."
xcodebuild -project GigEVirtualCamera.xcodeproj -target GigEVirtualCamera clean

# 3. Build Release configuration
echo -e "\n3. Building Release configuration..."
xcodebuild -project GigEVirtualCamera.xcodeproj \
           -target GigEVirtualCamera \
           -configuration Release \
           build \
           CODE_SIGN_IDENTITY="Developer ID Application: Luke  Chang (S368GH6KF7)" \
           DEVELOPMENT_TEAM="S368GH6KF7" \
           CODE_SIGN_STYLE="Manual" \
           PRODUCT_BUNDLE_IDENTIFIER="com.lukechang.GigEVirtualCamera"

# 4. Find the built app
RELEASE_APP=$(find ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*/Build/Products/Release -name "GigEVirtualCamera.app" | head -1)

if [ ! -d "$RELEASE_APP" ]; then
    echo "Error: Release app not found!"
    exit 1
fi

echo -e "\n4. Release app built at: $RELEASE_APP"

# 5. Sign all components properly
echo -e "\n5. Signing all components..."
/Users/lukechang/Github/hyperstudy-gige/Scripts/prepare_for_distribution.sh "$RELEASE_APP"

# 6. Copy to Applications
echo -e "\n6. Installing to /Applications..."
rm -rf /Applications/GigEVirtualCamera.app 2>/dev/null || true
cp -R "$RELEASE_APP" /Applications/

# 7. Reset camera subsystem
echo -e "\n7. Resetting camera subsystem..."
killall -9 cmioextension 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.cmio* 2>/dev/null || true

# 8. Launch the app
echo -e "\n8. Launching app..."
open /Applications/GigEVirtualCamera.app

echo -e "\n✅ Release build complete!"
echo -e "\nNext steps:"
echo "1. Check System Settings > Privacy & Security > Camera"
echo "2. Grant camera permissions if prompted"
echo "3. Open Photo Booth or QuickTime to test the virtual camera"
echo "4. If camera doesn't appear, restart your Mac"