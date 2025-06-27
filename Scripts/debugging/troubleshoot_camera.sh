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
# Check for System Extension (current implementation)
if [ -d "/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension" ]; then
    echo "   ✓ System Extension bundle found"
    EXTENSION_TYPE="systemextension"
    EXTENSION_PATH="/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension"
# Check for App Extension (legacy)
elif [ -d "/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex" ]; then
    echo "   ✓ App Extension bundle found"
    EXTENSION_TYPE="appex"
    EXTENSION_PATH="/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex"
else
    echo "   ✗ No extension bundle found"
    echo "   Looking for extensions..."
    find /Applications/GigEVirtualCamera.app -name "*.systemextension" -o -name "*.appex" 2>/dev/null
    exit 1
fi

# 3. Check code signing
echo -e "\n3. Checking code signing..."
codesign --verify --verbose=4 /Applications/GigEVirtualCamera.app 2>&1 | grep -E "(valid|satisfies)"

# 4. Check entitlements
echo -e "\n4. Checking extension entitlements..."
codesign -d --entitlements - "$EXTENSION_PATH" 2>&1 | grep -E "(camera|sandbox|application-groups)"

# 5. Try registration based on extension type
echo -e "\n5. Attempting registration..."
if [ "$EXTENSION_TYPE" = "appex" ]; then
    echo "   Registering App Extension with pluginkit..."
    pluginkit -a "$EXTENSION_PATH"
    sleep 1
elif [ "$EXTENSION_TYPE" = "systemextension" ]; then
    echo "   System Extensions are registered via the app"
    echo "   Checking systemextensionsctl..."
    systemextensionsctl list | grep -i gige || echo "   Extension not found in system extension list"
fi

# 6. Check registration
echo -e "\n6. Checking registration..."
if [ "$EXTENSION_TYPE" = "appex" ]; then
    pluginkit -m -p com.apple.cmio-camera-extension | grep -i gige || echo "   Extension not found in pluginkit"
else
    echo "   Checking system camera list..."
    system_profiler SPCameraDataType | grep -A3 "GigE Virtual Camera" || echo "   Camera not found in system profiler"
fi

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