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
           build

# 4. Find the built app
RELEASE_APP="/Users/lukechang/Github/hyperstudy-gige/build/Release/GigEVirtualCamera.app"

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
killall -9 GigECameraExtension 2>/dev/null || true
killall -9 cmioextension 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.cmio* 2>/dev/null || true

echo -e "\n✅ Release build complete!"

# Ask about notarization
echo -e "\n=====================================
The app has been built and signed with Developer ID.
For distribution outside the App Store, it needs to be notarized.

Would you like to notarize the app now? (y/n)"
read -r response

if [[ "$response" == "y" ]]; then
    echo -e "\nStarting notarization process..."
    /Users/lukechang/Github/hyperstudy-gige/Scripts/notarize.sh /Applications/GigEVirtualCamera.app
else
    echo -e "\nSkipping notarization. To notarize later, run:"
    echo "./Scripts/notarize.sh /Applications/GigEVirtualCamera.app"
    echo -e "\nNext steps for testing:"
    echo "1. Check System Settings > Privacy & Security > Camera"
    echo "2. Grant camera permissions if prompted"
    echo "3. Open Photo Booth or QuickTime to test the virtual camera"
    echo "4. If camera doesn't appear, restart your Mac"
fi