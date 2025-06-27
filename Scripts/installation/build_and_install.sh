#!/bin/bash

# Build and Install GigE Virtual Camera
# This script builds the app in Release mode and installs it to /Applications

set -e  # Exit on error

echo "🔨 Building GigE Virtual Camera in Release mode..."

# Change to the script directory
cd "$(dirname "$0")"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project GigEVirtualCamera.xcodeproj -scheme GigEVirtualCamera -configuration Release

# Build the app
echo "🏗️  Building Release version..."
xcodebuild build \
    -project GigEVirtualCamera.xcodeproj \
    -scheme GigEVirtualCamera \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    ONLY_ACTIVE_ARCH=NO

# Find the built app
APP_PATH="build/DerivedData/Build/Products/Release/GigEVirtualCamera.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Built app not found at $APP_PATH"
    exit 1
fi

echo "✅ Build successful!"

# Check if app already exists in Applications
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "⚠️  GigEVirtualCamera.app already exists in /Applications"
    read -p "Do you want to replace it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Installation cancelled"
        exit 1
    fi
    
    # Remove old app
    echo "🗑️  Removing old version..."
    sudo rm -rf "/Applications/GigEVirtualCamera.app"
fi

# Copy to Applications
echo "📦 Copying to /Applications..."
sudo cp -R "$APP_PATH" "/Applications/"

# Set proper permissions
echo "🔐 Setting permissions..."
sudo chown -R root:wheel "/Applications/GigEVirtualCamera.app"
sudo chmod -R 755 "/Applications/GigEVirtualCamera.app"

# Make the app executable
sudo chmod +x "/Applications/GigEVirtualCamera.app/Contents/MacOS/GigEVirtualCamera"
sudo chmod +x "/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension/Contents/MacOS/GigECameraExtension"

echo "✅ Installation complete!"
echo ""
echo "📌 Next steps:"
echo "1. Launch GigEVirtualCamera from /Applications"
echo "2. Grant camera permissions when prompted"
echo "3. Select your GigE camera from the dropdown"
echo "4. The virtual camera will appear in other apps as 'GigE Virtual Camera'"
echo ""
echo "🎥 You can test it in Photo Booth or FaceTime"