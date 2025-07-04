#!/bin/bash

echo "🚀 Installing GigE Virtual Camera (Debug Build)..."

# Find the debug build
BUILD_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "GigEVirtualCamera.app" -path "*/Debug/*" -type d | head -1)

if [ -z "$BUILD_PATH" ]; then
    echo "❌ Debug build not found. Please build the app first."
    exit 1
fi

echo "Found app at: $BUILD_PATH"

# Remove old app
echo "Removing old app..."
sudo rm -rf /Applications/GigEVirtualCamera.app

# Copy new app
echo "Installing new app..."
sudo cp -R "$BUILD_PATH" /Applications/

echo "✅ App installed successfully!"
echo ""
echo "Launching app..."
open /Applications/GigEVirtualCamera.app