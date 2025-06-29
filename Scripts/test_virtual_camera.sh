#!/bin/bash

# test_virtual_camera.sh - Test if the virtual camera is working after notarization

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}     GigE Virtual Camera Test${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Function to count cameras
count_cameras() {
    # Create a temporary test program
    cat > /tmp/test_cameras.swift << 'EOF'
import AVFoundation
import CoreMediaIO

// Enable virtual cameras
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)
var allow: UInt32 = 1
CMIOObjectSetPropertyData(
    CMIOObjectID(kCMIOObjectSystemObject),
    &prop,
    0,
    nil,
    UInt32(MemoryLayout<UInt32>.size),
    &allow
)

// Count AVFoundation cameras
let devices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.external, .builtInWideAngleCamera],
    mediaType: .video,
    position: .unspecified
).devices

print("AVFOUNDATION_COUNT:\(devices.count)")

// Count CMIO devices
var dataSize: UInt32 = 0
var devicesProperty = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

if CMIOObjectGetPropertyDataSize(
    CMIOObjectID(kCMIOObjectSystemObject),
    &devicesProperty,
    0,
    nil,
    &dataSize
) == noErr {
    let cmioCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
    print("CMIO_COUNT:\(cmioCount)")
}

// Look for our camera
for device in devices {
    if device.localizedName.contains("GigE") || device.modelID.contains("GigE") {
        print("GIGE_FOUND:true")
        print("GIGE_NAME:\(device.localizedName)")
        break
    }
}
EOF
    
    # Compile and run
    swiftc /tmp/test_cameras.swift -o /tmp/test_cameras 2>/dev/null
    /tmp/test_cameras 2>/dev/null
}

echo -e "${BLUE}1. Pre-flight checks${NC}"
echo "================================"

# Check if app is installed
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo -e "${GREEN}✓${NC} App installed at /Applications/GigEVirtualCamera.app"
else
    echo -e "${RED}✗${NC} App not found at /Applications/GigEVirtualCamera.app"
    exit 1
fi

# Check if app is notarized
SPCTL_OUTPUT=$(spctl -a -vvv /Applications/GigEVirtualCamera.app 2>&1)
if echo "$SPCTL_OUTPUT" | grep -q "source=Notarized Developer ID"; then
    echo -e "${GREEN}✓${NC} App is notarized"
elif echo "$SPCTL_OUTPUT" | grep -q "source=Developer ID"; then
    echo -e "${YELLOW}⚠${NC} App is signed but not notarized"
    echo "   Run ./Scripts/notarize.sh to notarize the app"
else
    echo -e "${RED}✗${NC} App signing issue:"
    echo "$SPCTL_OUTPUT" | grep "source=" | sed 's/^/   /'
fi

# Check if extension exists
if [ -d "/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex" ]; then
    echo -e "${GREEN}✓${NC} Camera extension found"
else
    echo -e "${RED}✗${NC} Camera extension missing"
    exit 1
fi

echo ""
echo -e "${BLUE}2. Testing camera discovery${NC}"
echo "================================"

# Get initial counts
echo "Checking camera devices..."
INITIAL_OUTPUT=$(count_cameras)
INITIAL_AV_COUNT=$(echo "$INITIAL_OUTPUT" | grep "AVFOUNDATION_COUNT:" | cut -d: -f2)
INITIAL_CMIO_COUNT=$(echo "$INITIAL_OUTPUT" | grep "CMIO_COUNT:" | cut -d: -f2)
INITIAL_GIGE=$(echo "$INITIAL_OUTPUT" | grep "GIGE_FOUND:" | cut -d: -f2)

echo "Before launching app:"
echo "  AVFoundation cameras: $INITIAL_AV_COUNT"
echo "  CMIO devices: $INITIAL_CMIO_COUNT"

if [[ "$INITIAL_GIGE" == "true" ]]; then
    GIGE_NAME=$(echo "$INITIAL_OUTPUT" | grep "GIGE_NAME:" | cut -d: -f2)
    echo -e "  ${GREEN}✓${NC} GigE Virtual Camera found: $GIGE_NAME"
else
    echo -e "  ${YELLOW}⚠${NC} GigE Virtual Camera not found"
fi

# Launch the app
echo ""
echo -e "${BLUE}3. Launching GigE Virtual Camera app${NC}"
echo "================================"
echo "Starting app..."

# Kill any existing instance
killall GigEVirtualCamera 2>/dev/null || true
sleep 1

# Launch the app
open /Applications/GigEVirtualCamera.app
sleep 3

# Check again
echo ""
echo "After launching app:"
AFTER_OUTPUT=$(count_cameras)
AFTER_AV_COUNT=$(echo "$AFTER_OUTPUT" | grep "AVFOUNDATION_COUNT:" | cut -d: -f2)
AFTER_CMIO_COUNT=$(echo "$AFTER_OUTPUT" | grep "CMIO_COUNT:" | cut -d: -f2)
AFTER_GIGE=$(echo "$AFTER_OUTPUT" | grep "GIGE_FOUND:" | cut -d: -f2)

echo "  AVFoundation cameras: $AFTER_AV_COUNT"
echo "  CMIO devices: $AFTER_CMIO_COUNT"

if [[ "$AFTER_GIGE" == "true" ]]; then
    GIGE_NAME=$(echo "$AFTER_OUTPUT" | grep "GIGE_NAME:" | cut -d: -f2)
    echo -e "  ${GREEN}✓${NC} GigE Virtual Camera found: $GIGE_NAME"
    
    echo ""
    echo -e "${GREEN}🎉 Success! Virtual camera is working!${NC}"
    echo ""
    echo "You can now:"
    echo "1. Open Photo Booth and select 'GigE Virtual Camera'"
    echo "2. Use QuickTime Player > File > New Movie Recording"
    echo "3. Use the camera in Zoom, Teams, or other apps"
else
    echo -e "  ${RED}✗${NC} GigE Virtual Camera not found"
    
    # Check if extension process is running
    echo ""
    echo "Checking extension process..."
    if ps aux | grep -i "GigECameraExtension" | grep -v grep > /dev/null; then
        echo -e "${GREEN}✓${NC} Extension process is running"
    else
        echo -e "${RED}✗${NC} Extension process not found"
    fi
    
    echo ""
    echo -e "${YELLOW}Troubleshooting suggestions:${NC}"
    echo "1. Make sure the app is notarized: ./Scripts/notarize.sh"
    echo "2. Try restarting your Mac"
    echo "3. Check Console.app for error messages"
    echo "4. Reset camera permissions in System Settings > Privacy & Security"
fi

# Clean up
rm -f /tmp/test_cameras.swift /tmp/test_cameras