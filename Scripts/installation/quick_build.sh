#!/bin/bash

# Quick build script that avoids the Xcode project issues
set -e

echo "🔨 Quick build for GigE Virtual Camera..."

# Clean
rm -rf build/QuickBuild

# Create directories
mkdir -p build/QuickBuild/GigEVirtualCamera.app/Contents/MacOS
mkdir -p build/QuickBuild/GigEVirtualCamera.app/Contents/Frameworks
mkdir -p build/QuickBuild/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension/Contents/MacOS
mkdir -p build/QuickBuild/GigEVirtualCamera.app/Contents/Resources

# Copy Info.plists
cp GigECameraApp/Info.plist build/QuickBuild/GigEVirtualCamera.app/Contents/
cp GigECameraExtension/Info.plist build/QuickBuild/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension/Contents/

# Navigate to project root
cd "$(dirname "$0")/../.."

# Try using xcodebuild with explicit file lists
echo "Building main app..."
xcodebuild -project GigEVirtualCamera.xcodeproj \
    -target GigEVirtualCamera \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    -scheme GigEVirtualCamera \
    build ONLY_ACTIVE_ARCH=NO || true

# Check if the build succeeded
if [ -d "build/DerivedData/Build/Products/Release/GigEVirtualCamera.app" ]; then
    echo "✅ Build found, copying to Applications..."
    
    # Remove old version if exists
    if [ -d "/Applications/GigEVirtualCamera.app" ]; then
        echo "Removing old version..."
        sudo rm -rf "/Applications/GigEVirtualCamera.app"
    fi
    
    # Copy new version
    sudo cp -R "build/DerivedData/Build/Products/Release/GigEVirtualCamera.app" "/Applications/"
    
    echo "✅ Installation complete!"
    echo "Launch GigEVirtualCamera from /Applications"
else
    echo "❌ Build failed. Checking build logs..."
    # Show last few lines of build log
    tail -n 50 build/DerivedData/Logs/Build/*.xcactivitylog 2>/dev/null || echo "No build logs found"
fi