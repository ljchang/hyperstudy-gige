#!/bin/bash

# Build development version of GigE Virtual Camera for local testing

set -e

echo "=== Building GigE Virtual Camera Development ===="

# 1. Clean and generate project
echo "1. Cleaning and generating project..."
cd /Users/lukechang/Github/hyperstudy-gige
xcodegen generate

# 2. Clean build folder
echo -e "\n2. Cleaning build folder..."
xcodebuild -project GigEVirtualCamera.xcodeproj -target GigEVirtualCamera clean

# 3. Build Debug configuration
echo -e "\n3. Building Debug configuration..."
xcodebuild -project GigEVirtualCamera.xcodeproj \
           -target GigEVirtualCamera \
           -configuration Debug \
           build

# 4. Find the built app
DEBUG_APP="/Users/lukechang/Github/hyperstudy-gige/build/Debug/GigEVirtualCamera.app"

if [ ! -d "$DEBUG_APP" ]; then
    echo "Error: Debug app not found!"
    exit 1
fi

echo -e "\n4. Debug app built at: $DEBUG_APP"

# 5. Sign with Apple Development certificate for local testing
echo -e "\n5. Signing for development..."
CODESIGN_IDENTITY="Apple Development" \
    /Users/lukechang/Github/hyperstudy-gige/Scripts/prepare_for_distribution.sh "$DEBUG_APP"

# 6. Copy to Applications
echo -e "\n6. Installing to /Applications..."
rm -rf /Applications/GigEVirtualCamera.app 2>/dev/null || true
cp -R "$DEBUG_APP" /Applications/

# 7. Reset camera subsystem
echo -e "\n7. Resetting camera subsystem..."
killall -9 GigECameraExtension 2>/dev/null || true
killall -9 cmioextension 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.cmio* 2>/dev/null || true

# 8. Launch the app
echo -e "\n8. Launching app..."
open /Applications/GigEVirtualCamera.app

echo -e "\n✅ Development build complete!"
echo -e "\nThis build is signed for local development only."
echo -e "For distribution, use ./Scripts/build_release.sh"
echo -e "\nNext steps:"
echo "1. Approve System Extension installation if prompted"
echo "2. Check System Settings > Privacy & Security > Camera"
echo "3. Test in Photo Booth or QuickTime"