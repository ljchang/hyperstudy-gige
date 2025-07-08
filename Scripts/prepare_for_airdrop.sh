#!/bin/bash

# prepare_for_airdrop.sh - Prepare app for AirDrop distribution
# This ensures the app will work when transferred via AirDrop

set -e

echo "Preparing GigE Virtual Camera for AirDrop"
echo "========================================"
echo ""

# Use the notarized app
APP_SOURCE="/Applications/GigEVirtualCamera.app"
OUTPUT_DIR="$HOME/Desktop"
ZIP_FILE="$OUTPUT_DIR/GigEVirtualCamera-Notarized.zip"

if [ ! -d "$APP_SOURCE" ]; then
    echo "ERROR: App not found at $APP_SOURCE"
    exit 1
fi

echo "Creating notarized zip for AirDrop..."
cd /Applications
zip -r "$ZIP_FILE" GigEVirtualCamera.app

echo ""
echo "✅ Created: $ZIP_FILE"
echo ""
echo "Instructions for distribution:"
echo "1. AirDrop the file: GigEVirtualCamera-Notarized.zip"
echo "2. On the target Mac:"
echo "   - Double-click the zip to extract"
echo "   - Drag GigEVirtualCamera.app to Applications"
echo "   - Right-click and choose 'Open' (first time only)"
echo ""
echo "This avoids some AirDrop-specific issues with apps."