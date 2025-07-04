#\!/bin/bash

echo "=== Complete Frame Flow Test ==="
echo "Testing all components of the GigE → App → Extension → Client flow"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check status
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        return 1
    fi
}

# 1. Check if app is running
echo "1. Checking Application Status:"
APP_PID=$(pgrep -f "GigEVirtualCamera.app" | head -1)
if [ -n "$APP_PID" ]; then
    check_status 0 "App is running (PID: $APP_PID)"
else
    check_status 1 "App is NOT running"
    echo "   Please start the app first"
fi

# 2. Check if extension is loaded
echo -e "\n2. Checking Extension Status:"
EXT_PID=$(pgrep -f "GigECameraExtension" | head -1)
if [ -n "$EXT_PID" ]; then
    check_status 0 "Extension is loaded (PID: $EXT_PID)"
else
    check_status 1 "Extension is NOT loaded"
fi

# 3. Check virtual camera in system
echo -e "\n3. Checking Virtual Camera Registration:"
CAMERA_FOUND=$(system_profiler SPCameraDataType 2>/dev/null | grep -c "GigE Virtual Camera")
if [ $CAMERA_FOUND -gt 0 ]; then
    check_status 0 "Virtual camera is registered in system"
else
    check_status 1 "Virtual camera NOT found in system"
fi

# 4. Check CMIO device discovery
echo -e "\n4. Testing CMIO Device Discovery:"
cat > /tmp/test_cmio_device.swift << 'SWIFTEOF'
import CoreMediaIO
import Foundation

var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, &dataSize)

let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
var deviceIDs = Array(repeating: CMIODeviceID(0), count: deviceCount)

CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, dataSize, &dataSize, &deviceIDs)

var found = false
for deviceID in deviceIDs {
    prop.mSelector = CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID)
    var nameSize: UInt32 = 0
    CMIOObjectGetPropertyDataSize(deviceID, &prop, 0, nil, &nameSize)
    
    var uid: CFString = "" as CFString
    CMIOObjectGetPropertyData(deviceID, &prop, 0, nil, nameSize, &nameSize, &uid)
    
    if (uid as String) == "4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4" {
        print("FOUND: Device with correct UID (ID: \(deviceID))")
        found = true
        
        // Check streams
        prop.mSelector = CMIOObjectPropertySelector(kCMIODevicePropertyStreams)
        CMIOObjectGetPropertyDataSize(deviceID, &prop, 0, nil, &dataSize)
        
        let streamCount = Int(dataSize) / MemoryLayout<CMIOStreamID>.size
        print("  Stream count: \(streamCount)")
        
        if streamCount >= 2 {
            print("  ✓ Has both sink and source streams")
        } else {
            print("  ✗ Missing streams")
        }
    }
}

if \!found {
    print("NOT FOUND: Device with UID 4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4")
}
SWIFTEOF

CMIO_RESULT=$(swift /tmp/test_cmio_device.swift 2>&1)
if echo "$CMIO_RESULT" | grep -q "FOUND"; then
    check_status 0 "CMIO device found with correct UID"
    echo "$CMIO_RESULT" | grep -E "(Stream count|✓|✗)" | sed 's/^/   /'
else
    check_status 1 "CMIO device NOT found"
fi
rm -f /tmp/test_cmio_device.swift

# 5. Check App Group communication
echo -e "\n5. Checking App Group Communication:"
PLIST="$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist"
if [ -f "$PLIST" ]; then
    check_status 0 "App Group preferences file exists"
    
    # Check StreamState
    STREAM_STATE=$(plutil -p "$PLIST" 2>/dev/null | grep -A3 "StreamState")
    if [ -n "$STREAM_STATE" ]; then
        echo "   Current stream state:"
        echo "$STREAM_STATE" | sed 's/^/     /'
    fi
else
    check_status 1 "App Group preferences file NOT found"
fi

# 6. Check if app is monitoring stream state
echo -e "\n6. Testing App Stream State Monitoring:"
# Set a test state
defaults write "$PLIST" StreamState -dict streamActive -bool YES timestamp -float $(date +%s) pid -int $$ 2>/dev/null

# Monitor logs for response
echo "   Monitoring app response for 3 seconds..."
MONITOR_OUTPUT=$(timeout 3 log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND (category == "CameraManager" OR category == "CMIOSinkConnector" OR category == "StreamStateMonitor")' 2>&1 | grep -E "(Extension signaled|handleStreamStateChange|Connecting to CMIO)" || true)

if [ -n "$MONITOR_OUTPUT" ]; then
    check_status 0 "App is responding to stream state changes"
    echo "$MONITOR_OUTPUT" | head -5 | sed 's/^/     /'
else
    check_status 1 "App is NOT responding to stream state changes"
    echo "   ${YELLOW}Note: App may need to be restarted to pick up code changes${NC}"
fi

# Clean up test state
defaults delete "$PLIST" StreamState 2>/dev/null

# 7. Check GigE camera connection
echo -e "\n7. Checking GigE Camera Connection:"
CAMERA_LOG=$(log show --style syslog --last 30s 2>/dev/null | grep "GigECameraManager" | grep -E "(Connected to camera|isConnected|Streaming)" | tail -3)
if [ -n "$CAMERA_LOG" ]; then
    echo "   Recent camera activity:"
    echo "$CAMERA_LOG" | sed 's/^/     /'
else
    echo "   ${YELLOW}No recent camera activity${NC}"
fi

# 8. Test complete flow
echo -e "\n8. Testing Complete Frame Flow:"
echo "   Opening Photo Booth to trigger client connection..."
open -a "Photo Booth" 2>/dev/null || echo "   ${YELLOW}Photo Booth not available${NC}"

sleep 3

# Check if extension signals need for frames
NEW_STATE=$(plutil -p "$PLIST" 2>/dev/null | grep -A3 "StreamState")
if echo "$NEW_STATE" | grep -q "streamActive.*1"; then
    check_status 0 "Extension is signaling need for frames"
else
    check_status 1 "Extension is NOT signaling need for frames"
fi

# Check for frame flow logs
echo -e "\n   Checking for frame flow activity:"
FRAME_LOG=$(log show --style syslog --last 10s 2>/dev/null | grep -E "(Sent frame|Received frame|sendSampleBuffer)" | tail -5)
if [ -n "$FRAME_LOG" ]; then
    check_status 0 "Frame flow detected"
    echo "$FRAME_LOG" | sed 's/^/     /'
else
    check_status 1 "No frame flow detected"
fi

echo -e "\n=== Summary ==="
echo "If you're not seeing video in Photo Booth, check:"
echo "1. Is the app running the latest code? (may need restart)"
echo "2. Is a GigE camera connected and streaming?"
echo "3. Are there any permission dialogs to approve?"
echo ""
echo "To monitor live activity, run:"
echo "  ./Scripts/monitor_frame_flow.sh"
