#!/bin/bash

# Install GigE Virtual Camera app to /Applications

echo "🚀 Installing GigE Virtual Camera..."

# Check if app exists
if [ ! -d "build/Release/GigEVirtualCamera.app" ]; then
    echo "❌ App not found at build/Release/GigEVirtualCamera.app"
    echo "Please build the app first"
    exit 1
fi

echo "📦 App found at build/Release/GigEVirtualCamera.app"

# Kill any running instances
echo "🛑 Stopping any running instances..."
killall GigEVirtualCamera 2>/dev/null || true

# Remove old version
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "🗑️  Removing old version..."
    rm -rf "/Applications/GigEVirtualCamera.app"
fi

# Copy new version
echo "📁 Installing new version..."
cp -R "build/Release/GigEVirtualCamera.app" "/Applications/"

# Verify installation
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "✅ Successfully installed to /Applications"
    
    # Check extension
    if [ -d "/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex" ]; then
        echo "✅ Camera extension found"
    else
        echo "⚠️  Camera extension not found in bundle"
    fi
    
    echo ""
    echo "🎯 Next steps:"
    echo "1. Run the app: open /Applications/GigEVirtualCamera.app"
    echo "2. Check if virtual camera appears in QuickTime or other apps"
    echo "3. If not visible, check Console.app for errors"
else
    echo "❌ Installation failed"
    exit 1
fi