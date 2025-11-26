#!/bin/bash

echo "=== GigE Virtual Camera CMIO System Extension Troubleshooting ==="
echo
echo "This script checks for common issues with CMIO System Extensions"
echo

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Check if app is installed correctly
echo "1. Checking app installation..."
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo -e "   ${GREEN}✓${NC} App found at /Applications/GigEVirtualCamera.app"
else
    echo -e "   ${RED}✗${NC} App not found in /Applications"
    echo "   ${YELLOW}Fix: Install the app to /Applications/${NC}"
    exit 1
fi

# 2. Check system extension bundle
echo -e "\n2. Checking system extension bundle..."
SYSEXT_PATH="/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
if [ -d "$SYSEXT_PATH" ]; then
    echo -e "   ${GREEN}✓${NC} System Extension bundle found"
else
    echo -e "   ${RED}✗${NC} System Extension bundle not found at expected path"
    echo "   Looking for extension..."
    find /Applications/GigEVirtualCamera.app -name "*.systemextension" -type d 2>/dev/null
fi

# 3. Check if extension is installed in system
echo -e "\n3. Checking system extension installation..."
EXTENSION_INSTALLED=$(systemextensionsctl list | grep "com.lukechang.GigEVirtualCamera.Extension")
if [ ! -z "$EXTENSION_INSTALLED" ]; then
    echo -e "   ${GREEN}✓${NC} System extension is installed:"
    echo "   $EXTENSION_INSTALLED"
else
    echo -e "   ${RED}✗${NC} System extension not installed"
    echo "   ${YELLOW}Fix: Launch the app and click 'Install Extension'${NC}"
fi

# 4. Check code signing
echo -e "\n4. Checking code signing..."
echo "   App signature:"
codesign --verify --verbose=2 /Applications/GigEVirtualCamera.app 2>&1 | head -3
echo "   Extension signature:"
codesign --verify --verbose=2 "$SYSEXT_PATH" 2>&1 | head -3

# 5. Check entitlements
echo -e "\n5. Checking entitlements..."
echo "   App entitlements:"
codesign -d --entitlements - /Applications/GigEVirtualCamera.app 2>&1 | grep -E "(system-extension|camera)" | head -5
echo "   Extension entitlements:"
codesign -d --entitlements - "$SYSEXT_PATH" 2>&1 | grep -E "(camera|sandbox|application-groups)" | head -5

# 6. Check CMIO registration
echo -e "\n6. Checking CMIO registration..."
# Check if the extension is registered with CMIO
CMIO_DEVICES=$(system_profiler SPCameraDataType 2>/dev/null | grep -A5 "GigE Virtual Camera")
if [ ! -z "$CMIO_DEVICES" ]; then
    echo -e "   ${GREEN}✓${NC} Camera found in system:"
    echo "$CMIO_DEVICES" | sed 's/^/   /'
else
    echo -e "   ${RED}✗${NC} Camera not found in system"
    echo "   Checking all cameras:"
    system_profiler SPCameraDataType | grep -E "^    [A-Za-z].*:|Model ID:" | head -10
fi

# 7. Check extension logs
echo -e "\n7. Recent extension logs..."
echo "   Checking for CMIO extension errors:"
log show --predicate 'subsystem == "com.apple.cmio" AND (eventMessage CONTAINS "GigE" OR eventMessage CONTAINS "lukechang")' --style syslog --last 5m 2>/dev/null | tail -10

echo "   Checking for extension-specific logs:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --style syslog --last 5m 2>/dev/null | tail -10

# 8. Check system extension manager logs
echo -e "\n8. System Extension Manager logs..."
log show --predicate 'subsystem == "com.apple.extensionKit" AND eventMessage CONTAINS "lukechang"' --style syslog --last 5m 2>/dev/null | tail -10

# 9. Test with sample app
echo -e "\n9. Testing with QuickTime..."
echo "   Opening QuickTime Player..."
echo "   ${YELLOW}Please check if 'GigE Virtual Camera' appears in the camera list${NC}"
open -a "QuickTime Player"

# 10. Recommendations
echo -e "\n=== Troubleshooting Steps ==="
echo "If the camera is not appearing:"
echo
echo "1. ${YELLOW}Enable Developer Mode:${NC}"
echo "   sudo systemextensionsctl developer on"
echo
echo "2. ${YELLOW}Reset System Extensions:${NC}"
echo "   sudo systemextensionsctl reset"
echo
echo "3. ${YELLOW}Check Privacy & Security:${NC}"
echo "   System Settings > Privacy & Security > Camera"
echo "   - Ensure GigE Virtual Camera is allowed"
echo
echo "4. ${YELLOW}Check Login Items & Extensions:${NC}"
echo "   System Settings > General > Login Items & Extensions"
echo "   - Look for 'Camera Extensions' section"
echo "   - Ensure 'GigE Camera Extension' is toggled ON"
echo
echo "5. ${YELLOW}Reinstall the extension:${NC}"
echo "   - Launch GigEVirtualCamera app"
echo "   - Click 'Uninstall Extension'"
echo "   - Restart your Mac"
echo "   - Launch app again and click 'Install Extension'"
echo
echo "6. ${YELLOW}Check Console for detailed logs:${NC}"
echo "   - Open Console.app"
echo "   - Search for 'GigE' or 'cmio'"
echo "   - Look for any error messages"

echo -e "\n${GREEN}Script completed!${NC}"