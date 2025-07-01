#!/bin/bash

# Build and install GigE Virtual Camera with System Extension

set -e

echo "=== Building and Installing GigE Virtual Camera System Extension ==="
echo

# 1. Check if we have the right permissions
if [ "$EUID" -eq 0 ]; then 
   echo "Please do not run this script as root/sudo"
   exit 1
fi

# 2. Navigate to project directory
cd /Users/lukechang/Github/hyperstudy-gige

# 3. Clean previous builds
echo "1. Cleaning previous builds..."
rm -rf ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*
rm -rf /Applications/GigEVirtualCamera.app 2>/dev/null || true

# 4. Kill any existing extension processes
echo "2. Stopping existing extension processes..."
killall -9 GigECameraExtension 2>/dev/null || true
killall -9 cmioextension 2>/dev/null || true

# 5. Generate Xcode project
echo "3. Generating Xcode project..."
xcodegen generate

# 6. Build the app
echo "4. Building app..."
xcodebuild -project GigEVirtualCamera.xcodeproj \
           -scheme GigEVirtualCamera \
           -configuration Release \
           build

# 7. Find the built app
BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*/Build/Products/Release -name "GigEVirtualCamera.app" | head -1)

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Error: Built app not found!"
    exit 1
fi

echo "5. Built app found at: $BUILT_APP"

# 8. Sign the app properly (inside-out)
echo "6. Signing app components..."

# First sign any frameworks in the app
if [ -d "$BUILT_APP/Contents/Frameworks" ]; then
    for framework in "$BUILT_APP/Contents/Frameworks"/*.dylib; do
        if [ -f "$framework" ]; then
            codesign --force --sign - "$framework"
        fi
    done
fi

# Sign the system extension
EXTENSION_PATH="$BUILT_APP/Contents/Library/SystemExtensions/GigECameraExtension.appex"
if [ -d "$EXTENSION_PATH" ]; then
    # Sign any frameworks in the extension
    if [ -d "$EXTENSION_PATH/Contents/Frameworks" ]; then
        for framework in "$EXTENSION_PATH/Contents/Frameworks"/*.dylib; do
            if [ -f "$framework" ]; then
                codesign --force --sign - "$framework"
            fi
        done
    fi
    
    # Sign the extension itself
    codesign --force --sign - --deep "$EXTENSION_PATH"
    echo "   ✅ Extension signed"
else
    echo "   ❌ Warning: System extension not found at expected path!"
    echo "      Expected: $EXTENSION_PATH"
fi

# Sign the main app
codesign --force --sign - --deep "$BUILT_APP"
echo "   ✅ App signed"

# 9. Copy to Applications
echo "7. Installing to /Applications..."
cp -R "$BUILT_APP" /Applications/

# 10. Verify installation
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "   ✅ App installed to /Applications"
else
    echo "   ❌ Failed to install app"
    exit 1
fi

# 11. Clear caches
echo "8. Clearing system caches..."
rm -rf ~/Library/Caches/com.apple.cmio* 2>/dev/null || true

echo
echo "=== Installation Complete ==="
echo
echo "Next steps:"
echo "1. Run the app: open /Applications/GigEVirtualCamera.app"
echo "2. When prompted, approve the system extension in System Settings > Privacy & Security"
echo "3. After approval, restart the app"
echo "4. Check virtual camera in QuickTime or Photo Booth"
echo
echo "To check extension status: ./Scripts/check_system_extension.sh"