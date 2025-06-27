#!/bin/bash

echo "Building GigE Virtual Camera..."
echo "=============================="

# Build the project
xcodebuild -project GigEVirtualCamera.xcodeproj -scheme GigEVirtualCamera -configuration Debug build 2>&1 | tail -20

# Find the built app
echo ""
echo "Looking for built app..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-* -name "GigEVirtualCamera.app" -type d 2>/dev/null | grep -v "Index.noindex" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ App not found. Build may have failed."
    echo ""
    echo "Try building from Xcode:"
    echo "1. The project is now open in Xcode"
    echo "2. Select 'My Mac' as the destination"
    echo "3. Press Cmd+B to build"
    echo "4. Press Cmd+R to run"
else
    echo "✅ App found at: $APP_PATH"
    echo ""
    echo "Options:"
    echo "1. Run from current location:"
    echo "   open \"$APP_PATH\""
    echo ""
    echo "2. Copy to Desktop and run:"
    echo "   cp -R \"$APP_PATH\" ~/Desktop/"
    echo "   open ~/Desktop/GigEVirtualCamera.app"
fi