#!/bin/bash

echo "🔧 Fixing GigE Virtual Camera Discoverability"
echo "This will ONLY fix the camera visibility issue"
echo ""

# Step 1: Check if extension is installed
echo "1. Checking system extension status..."
systemextensionsctl list | grep com.lukechang

# Step 2: Force reinstall the extension
echo -e "\n2. Reinstalling system extension..."
echo "Please run the app and click 'Allow' when prompted"

# Launch the app to trigger extension installation
open /Applications/GigEVirtualCamera.app

echo -e "\n⏳ Waiting for extension installation..."
echo "👉 When you see the system prompt:"
echo "   1. Click 'Open System Settings' or go to System Settings > Privacy & Security"
echo "   2. Look for 'GigE Virtual Camera' and click 'Allow'"
echo "   3. You may need to enter your password"

sleep 15

# Step 3: Verify installation
echo -e "\n3. Verifying extension installation..."
systemextensionsctl list | grep com.lukechang

# Step 4: Check CMIO registration
echo -e "\n4. Checking camera registration..."
system_profiler SPCameraDataType | grep -A5 -B5 "GigE"

echo -e "\n✅ Done!"
echo ""
echo "To test:"
echo "1. Open Photo Booth or FaceTime"
echo "2. Look for 'GigE Virtual Camera' in camera selection"
echo ""
echo "If still not visible:"
echo "1. Restart your Mac"
echo "2. Make sure the GigE camera is connected and visible in the app"
echo "3. Check Console.app for any CMIO errors"