#!/bin/bash

echo "🔍 Fixing GigE Virtual Camera Discovery"
echo "======================================"
echo ""

# Step 1: Check current state
echo "1️⃣ Current system extension status:"
systemextensionsctl list | grep -E "enabled|com.lukechang" || echo "No extensions found"

# Step 2: Check CMIO registration
echo -e "\n2️⃣ Checking CMIO camera registration:"
system_profiler SPCameraDataType | grep -A5 -B5 "GigE" || echo "No GigE camera found in system"

# Step 3: Launch app to trigger extension installation
echo -e "\n3️⃣ Launching app to install system extension..."
echo "⚠️  IMPORTANT: When prompted:"
echo "   - Click 'Open System Settings' or go to System Settings > Privacy & Security"
echo "   - Look for 'System Extension Blocked' notification"
echo "   - Click 'Allow' next to GigE Virtual Camera"
echo "   - Enter your password when prompted"
echo ""
read -p "Press Enter to launch the app..."

# Launch the app
open /Applications/GigEVirtualCamera.app

# Wait for user to approve
echo -e "\n⏳ Waiting for you to approve the extension..."
echo "After approving, press Enter to continue..."
read -p ""

# Step 4: Verify installation
echo -e "\n4️⃣ Verifying installation:"
systemextensionsctl list | grep -E "enabled|com.lukechang"

# Step 5: Check if camera is now visible
echo -e "\n5️⃣ Checking if camera is discoverable:"
log show --predicate 'subsystem == "com.apple.cmio"' --last 1m | grep -i "gige" | tail -5

echo -e "\n✅ Done! Please check:"
echo "1. Open Photo Booth or FaceTime"
echo "2. Look for 'GigE Virtual Camera' in camera selection"
echo ""
echo "If still not visible:"
echo "- Restart your Mac"
echo "- Make sure a GigE camera is connected and visible in the app"