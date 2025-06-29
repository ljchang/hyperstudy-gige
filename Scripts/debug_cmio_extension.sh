#!/bin/bash

echo "🔍 Debugging CMIO Extension for GigE Virtual Camera"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Check if app is running
echo -e "\n${YELLOW}1. Checking app process:${NC}"
APP_PID=$(pgrep -f "GigEVirtualCamera.app/Contents/MacOS/GigEVirtualCamera")
if [ -n "$APP_PID" ]; then
    echo -e "${GREEN}✓ App is running (PID: $APP_PID)${NC}"
else
    echo -e "${RED}✗ App is not running${NC}"
    echo "Please run: open /Applications/GigEVirtualCamera.app"
fi

# 2. Check if extension process is running
echo -e "\n${YELLOW}2. Checking extension process:${NC}"
EXT_PID=$(pgrep -f "GigECameraExtension.appex")
if [ -n "$EXT_PID" ]; then
    echo -e "${GREEN}✓ Extension is running (PID: $EXT_PID)${NC}"
else
    echo -e "${RED}✗ Extension process not found${NC}"
fi

# 3. Check if extension is properly installed
echo -e "\n${YELLOW}3. Checking extension installation:${NC}"
if [ -d "/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex" ]; then
    echo -e "${GREEN}✓ Extension found in app bundle${NC}"
    
    # Check Info.plist
    if plutil -p "/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex/Contents/Info.plist" | grep -q "NSExtension"; then
        echo -e "${GREEN}✓ Extension Info.plist contains NSExtension key${NC}"
    else
        echo -e "${RED}✗ Extension Info.plist missing NSExtension key${NC}"
    fi
else
    echo -e "${RED}✗ Extension not found in app bundle${NC}"
fi

# 4. Check if camera appears in system
echo -e "\n${YELLOW}4. Checking system camera list:${NC}"
CAMERA_COUNT=$(system_profiler SPCameraDataType 2>/dev/null | grep -c "GigE Virtual Camera")
if [ "$CAMERA_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ GigE Virtual Camera found in system${NC}"
    system_profiler SPCameraDataType 2>/dev/null | grep -A5 "GigE Virtual Camera"
else
    echo -e "${RED}✗ GigE Virtual Camera not found in system${NC}"
fi

# 5. Check CMIO subsystem
echo -e "\n${YELLOW}5. Checking CMIO subsystem:${NC}"
# Check if any CMIO extensions are loaded
CMIO_COUNT=$(ioreg -l | grep -c "CMIOExtension")
if [ "$CMIO_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ CMIO extensions detected in system ($CMIO_COUNT found)${NC}"
else
    echo -e "${RED}✗ No CMIO extensions detected${NC}"
fi

# 6. Check recent system logs
echo -e "\n${YELLOW}6. Recent CMIO/Extension errors (last 60 seconds):${NC}"
log show --predicate 'eventMessage CONTAINS[c] "cmio" OR eventMessage CONTAINS[c] "GigE" OR eventMessage CONTAINS[c] "camera extension"' --last 1m --style compact 2>/dev/null | grep -E "(error|fail|denied|crash)" | head -10

# 7. Check launchd services
echo -e "\n${YELLOW}7. Checking launchd services:${NC}"
launchctl list | grep -i "camera\|cmio" | head -10

# 8. Check code signing
echo -e "\n${YELLOW}8. Checking code signing:${NC}"
echo "App signing:"
codesign -dvv /Applications/GigEVirtualCamera.app 2>&1 | grep -E "(Identifier|TeamIdentifier|Authority)" | head -5
echo -e "\nExtension signing:"
codesign -dvv /Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex 2>&1 | grep -E "(Identifier|TeamIdentifier|Authority)" | head -5

# 9. Test with sample CMIO client
echo -e "\n${YELLOW}9. Testing camera discovery:${NC}"
# Try to list available cameras using a simple test
cat > /tmp/test_cmio.swift << 'EOF'
import AVFoundation
import CoreMediaIO

// Allow discovery of CMIO devices
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)
var allow: UInt32 = 1
CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, UInt32(MemoryLayout<UInt32>.size), &allow)

// List all video devices
let devices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.external, .builtInWideAngleCamera],
    mediaType: .video,
    position: .unspecified
).devices

print("Found \(devices.count) video devices:")
for device in devices {
    print("- \(device.localizedName) (\(device.modelID))")
}
EOF

swift /tmp/test_cmio.swift 2>/dev/null || echo -e "${RED}✗ Failed to run camera discovery test${NC}"
rm -f /tmp/test_cmio.swift

# 10. Suggestions
echo -e "\n${YELLOW}10. Troubleshooting suggestions:${NC}"
if [ -z "$EXT_PID" ]; then
    echo "• Extension is not running. Try:"
    echo "  - Restart the app"
    echo "  - Check Console.app for detailed error messages"
    echo "  - Ensure app is code signed with valid Developer ID"
fi

if [ "$CAMERA_COUNT" -eq 0 ]; then
    echo "• Camera not appearing in system. Try:"
    echo "  - Quit all camera-using apps (FaceTime, Zoom, etc.)"
    echo "  - Restart the camera subsystem: sudo killall VDCAssistant"
    echo "  - Restart your Mac"
fi

echo -e "\n${YELLOW}Additional debugging:${NC}"
echo "• Open Console.app and filter for 'GigE' or 'com.lukechang.GigEVirtualCamera'"
echo "• Look for any crash reports in Console.app under 'Crash Reports'"
echo "• Try opening QuickTime Player > File > New Movie Recording"
echo "• Check if the camera appears in the camera dropdown"