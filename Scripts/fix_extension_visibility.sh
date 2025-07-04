#!/bin/bash

echo "=== Fixing GigE Virtual Camera Extension Visibility ==="
echo ""

# Kill any running processes
echo "1. Stopping existing processes..."
killall GigEVirtualCamera 2>/dev/null
killall GigECameraExtension 2>/dev/null
sleep 2

# Reset system extensions
echo "2. Resetting system extensions..."
systemextensionsctl reset

# Launch the app to reinstall extension
echo "3. Launching app to install extension..."
open /Users/lukechang/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-gwoebjnyoldbeyedqrzcrnlowqcw/Build/Products/Debug/GigEVirtualCamera.app

echo "4. Waiting for extension installation..."
sleep 5

# Check extension status
echo "5. Checking extension status..."
systemextensionsctl list | grep -A5 "com.lukechang" || echo "Extension not found"

# Force extension activation
echo "6. Checking for extension approval dialog..."
echo "   If you see a system dialog asking to approve the extension, please click Allow"
sleep 3

# Check if camera is visible
echo "7. Checking camera visibility..."
system_profiler SPCameraDataType 2>&1 | grep -A5 "GigE" || echo "Camera not visible yet"

echo ""
echo "8. Opening Photo Booth to test..."
open -a "Photo Booth"

echo ""
echo "=== Instructions ==="
echo "1. In the GigEVirtualCamera app, click 'Install Extension' if needed"
echo "2. Approve any system dialogs that appear"
echo "3. Check Photo Booth - the camera should appear in the camera menu"
echo "4. If not visible, try restarting Photo Booth"