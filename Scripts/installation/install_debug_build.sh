#!/bin/bash

echo "📦 Installing the last working Debug build..."

APP_PATH="/Users/lukechang/Github/hyperstudy-gige/macos/build/Build/Products/Debug/GigEVirtualCamera.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Debug build not found at $APP_PATH"
    exit 1
fi

echo "✅ Found working Debug build"

echo "🗑️  Removing current version..."
sudo rm -rf /Applications/GigEVirtualCamera.app

echo "📦 Installing working Debug build..."
sudo cp -R "$APP_PATH" /Applications/

echo "🔐 Setting permissions..."
sudo chown -R root:wheel /Applications/GigEVirtualCamera.app
sudo chmod -R 755 /Applications/GigEVirtualCamera.app

echo "✅ Installation complete!"
echo ""
echo "This is the last working version with:"
echo "- ✅ Working GigE camera connection"
echo "- ✅ Working preview"
echo "- ✅ Working system extension"
echo ""
echo "Now run ./fix_camera_discovery.sh to make it discoverable in other apps"