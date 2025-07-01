#!/bin/bash

set -e

echo "=== CMIO Extension Test Script ==="

# Build the app
echo -e "\n1. Building the app..."
cd /Users/lukechang/Github/hyperstudy-gige
xcodebuild -project GigEVirtualCamera.xcodeproj -scheme GigECameraApp -configuration Debug build

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "GigEVirtualCamera.app" -type d | head -n 1)
echo "Built app found at: $APP_PATH"

# Copy to Applications
echo -e "\n2. Copying app to /Applications..."
sudo rm -rf /Applications/GigEVirtualCamera.app
sudo cp -R "$APP_PATH" /Applications/

# Reset system extensions
echo -e "\n3. Resetting system extensions..."
systemextensionsctl reset

# Run the app to install extension
echo -e "\n4. Running the app to install extension..."
echo "Please click 'Install Extension' in the app window that appears."
open /Applications/GigEVirtualCamera.app

# Wait for user to install
echo -e "\nPress Enter after you've installed the extension and granted permissions..."
read

# Check if extension is installed
echo -e "\n5. Checking extension status..."
./Scripts/debug_cmio_extension.sh

# Test with QuickTime
echo -e "\n6. Opening QuickTime to test camera..."
echo "In QuickTime: File ’ New Movie Recording ’ Select 'GigE Virtual Camera'"
open -a "QuickTime Player"

echo -e "\n=== Test Complete ==="