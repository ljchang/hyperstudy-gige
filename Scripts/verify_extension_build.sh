#!/bin/bash

echo "=== Verifying Extension Build and Debug Output ==="
echo ""

# First, rebuild the extension with our debug code
echo "1. Rebuilding extension..."
cd /Users/lukechang/Github/hyperstudy-gige
xcodebuild -project GigEVirtualCamera.xcodeproj -scheme GigECameraExtension -configuration Debug clean build 2>&1 | grep -E "(SUCCEEDED|FAILED|error:|warning:|SharedMemoryFramePool)"

echo ""
echo "2. Checking extension binary..."
EXTENSION_PATH="/Library/SystemExtensions/94816483-D32C-47D0-83F3-57C74143F9B9/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/MacOS/GigECameraExtension"
if [ -f "$EXTENSION_PATH" ]; then
    echo "Extension binary exists"
    ls -la "$EXTENSION_PATH"
    echo "Binary modified: $(stat -f "%Sm" "$EXTENSION_PATH")"
else
    echo "Extension binary NOT FOUND!"
fi

echo ""
echo "3. Reinstalling extension..."
# Kill processes
pkill -f GigEVirtualCamera.app || true
pkill -f GigECameraExtension || true
pkill -f "Photo Booth" || true
sleep 2

# Clear shared data
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true

# Install the app (which should trigger extension installation)
echo "Installing app..."
cp -R build/Debug/GigEVirtualCamera.app /Applications/ 2>/dev/null || echo "Failed to copy app"

# Open the app to trigger extension installation
open /Applications/GigEVirtualCamera.app
sleep 3

# The app should prompt to install the extension
echo ""
echo "4. Please click 'Install Extension' in the app UI if prompted..."
echo "   Waiting 10 seconds for manual action..."
sleep 10

# Now test
echo ""
echo "5. Opening Photo Booth to load extension..."
open -a "Photo Booth"
sleep 5

echo ""
echo "6. Checking if IOSurface IDs are shared..."
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || echo "No shared data"

echo ""
echo "7. Checking console output..."
# Look for our debug print statements
log show --predicate 'eventMessage CONTAINS "SharedMemoryFramePool" OR eventMessage CONTAINS "🚀" OR eventMessage CONTAINS "🎬"' --last 2m 2>/dev/null | tail -20