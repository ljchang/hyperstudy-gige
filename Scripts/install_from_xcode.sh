#!/bin/bash

echo "🚀 Installing GigE Virtual Camera from Xcode build..."

# Find the latest build
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*/Build/Products/Debug -name "GigEVirtualCamera.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ App not found in Xcode DerivedData"
    echo "Please build the app in Xcode first"
    exit 1
fi

echo "📦 Found app at: $APP_PATH"

# Kill any running instances
echo "🛑 Stopping any running instances..."
killall GigEVirtualCamera 2>/dev/null || true
sleep 1

# Remove old version
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "🗑️  Removing old version..."
    sudo rm -rf "/Applications/GigEVirtualCamera.app"
fi

# Copy new version
echo "📁 Installing new version..."
sudo cp -R "$APP_PATH" "/Applications/"

# Fix permissions
sudo chown -R $(whoami):staff "/Applications/GigEVirtualCamera.app"

# Verify installation
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "✅ Successfully installed to /Applications"
    echo ""
    echo "🚀 Starting the app..."
    open /Applications/GigEVirtualCamera.app
else
    echo "❌ Installation failed"
    exit 1
fi