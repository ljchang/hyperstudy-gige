#!/bin/bash

# Install GigE Virtual Camera to /Applications

echo "📦 Installing GigE Virtual Camera..."

# Check if app exists
if [ ! -d "GigEVirtualCamera.app" ]; then
    echo "❌ Error: GigEVirtualCamera.app not found in current directory"
    exit 1
fi

# Check if already installed
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "⚠️  GigEVirtualCamera.app already exists in /Applications"
    read -p "Do you want to replace it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Installation cancelled"
        exit 1
    fi
    
    # Remove old version
    echo "🗑️  Removing old version..."
    sudo rm -rf "/Applications/GigEVirtualCamera.app"
fi

# Copy to Applications
echo "📦 Copying to /Applications (requires admin password)..."
sudo cp -R GigEVirtualCamera.app /Applications/

# Set permissions
echo "🔐 Setting permissions..."
sudo chown -R root:wheel "/Applications/GigEVirtualCamera.app"
sudo chmod -R 755 "/Applications/GigEVirtualCamera.app"

echo "✅ Installation complete!"
echo ""
echo "📌 Next steps:"
echo "1. Launch GigEVirtualCamera from /Applications"
echo "2. Grant camera permissions when prompted"
echo "3. Select your GigE camera from the dropdown"
echo "4. The virtual camera will appear in other apps as 'GigE Virtual Camera'"
echo ""
echo "🎥 You can test it in Photo Booth or FaceTime"