#!/bin/bash

echo "Fixing GigE Virtual Camera Build"
echo "================================"

# Clean everything
echo "1. Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*

# Try to build just the app target
echo ""
echo "2. Building app target directly..."
xcodebuild -project GigEVirtualCamera.xcodeproj -target GigEVirtualCamera -configuration Debug build

# Check if it worked
echo ""
echo "3. Looking for built app..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-* -name "GigEVirtualCamera.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ App still not found"
    echo ""
    echo "Try this in Xcode:"
    echo "1. Open Xcode (should already be open)"
    echo "2. In the scheme selector (top bar), make sure 'GigEVirtualCamera' is selected"
    echo "3. Make sure 'My Mac' is the destination"
    echo "4. Product → Clean Build Folder (Shift+Cmd+K)"
    echo "5. Product → Build (Cmd+B)"
    echo ""
    echo "If that doesn't work:"
    echo "1. Click on the scheme dropdown → Edit Scheme"
    echo "2. In 'Build' tab, make sure 'GigEVirtualCamera' is checked"
    echo "3. Make sure it's set to build for 'Run'"
else
    echo "✅ App found at: $APP_PATH"
    echo ""
    echo "Run it with:"
    echo "open \"$APP_PATH\""
fi