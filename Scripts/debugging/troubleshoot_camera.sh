#!/bin/bash

echo "=== GigE Virtual Camera Troubleshooting ==="
echo

# 1. Check if app is installed
echo "1. Checking app installation..."
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "   ✓ App found at /Applications/GigEVirtualCamera.app"
else
    echo "   ✗ App not found in /Applications"
    exit 1
fi

# 2. Check extension bundle
echo -e "\n2. Checking extension bundle..."
if [ -d "/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex" ]; then
    echo "   ✓ Extension bundle found"
else
    echo "   ✗ Extension bundle not found"
    exit 1
fi

# 3. Check code signing
echo -e "\n3. Checking code signing..."
codesign --verify --verbose=4 /Applications/GigEVirtualCamera.app 2>&1 | grep -E "(valid|satisfies)"

# 4. Check entitlements
echo -e "\n4. Checking extension entitlements..."
codesign -d --entitlements - /Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex 2>&1 | grep -E "(camera|sandbox|application-groups)"

# 5. Try manual plugin registration
echo -e "\n5. Attempting manual registration..."
pluginkit -a /Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex
sleep 1

# 6. Check registration
echo -e "\n6. Checking registration..."
pluginkit -m -p com.apple.cmio-camera-extension | grep -i gige || echo "   Extension not found in pluginkit"

# 7. Check Privacy & Security settings
echo -e "\n7. Camera Privacy Settings..."
echo "   Please check:"
echo "   - System Settings > Privacy & Security > Camera"
echo "   - Look for GigE Virtual Camera and ensure it's enabled"

# 8. Check Login Items & Extensions
echo -e "\n8. System Extensions..."
echo "   Please check:"
echo "   - System Settings > General > Login Items & Extensions"
echo "   - Look for Camera Extensions section"
echo "   - Ensure GigE Camera Extension is toggled ON"

# 9. Launch the app
echo -e "\n9. Launching app..."
echo "   Opening GigEVirtualCamera app..."
open /Applications/GigEVirtualCamera.app

echo -e "\n10. Next Steps:"
echo "   1. In the app, click 'Install Extension' if prompted"
echo "   2. Grant any permission requests"
echo "   3. Restart applications that use cameras (Zoom, Teams, etc.)"
echo "   4. Select 'GigE Virtual Camera' as your camera source"

echo -e "\n=== If the camera still doesn't appear ==="
echo "1. Restart your Mac"
echo "2. Check Console.app for errors containing 'GigE' or 'cmio'"
echo "3. The extension requires approval from Apple for the camera entitlement"
echo "   - This is a known limitation for third-party camera extensions"
echo "   - Consider using OBS Virtual Camera as an alternative"

echo -e "\nDone!"