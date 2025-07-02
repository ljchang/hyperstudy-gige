#!/bin/bash

echo "=== Extension Stream Diagnosis ==="
echo ""

# 1. Basic checks
echo "1. Process status:"
ps aux | grep -E "GigECameraExtension|Photo Booth" | grep -v grep | awk '{print "   ", $11, "PID:", $2}'

# 2. Check if Photo Booth can see the camera
echo ""
echo "2. Camera visible to system:"
system_profiler SPCameraDataType 2>/dev/null | grep -A2 "GigE Virtual Camera" | head -3

# 3. Key question: Is the stream actually being requested?
echo ""
echo "3. Checking for stream start request..."
echo "   (In Photo Booth, make sure 'GigE Virtual Camera' is selected)"

# 4. Try to trigger extension activity by querying CMIO
echo ""
echo "4. CMIO device check:"
cat > /tmp/check_cmio.swift << 'EOF'
import CoreMediaIO
import Foundation

// Check if our camera is registered
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, &dataSize)

let deviceCount = dataSize / UInt32(MemoryLayout<CMIODeviceID>.size)
print("Found \(deviceCount) CMIO devices")

// List devices
var devices = Array(repeating: CMIODeviceID(), count: Int(deviceCount))
CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, dataSize, &dataSize, &devices)

for device in devices {
    var name: Unmanaged<CFString>?
    var nameProp = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    
    var nameSize = UInt32(MemoryLayout<CFString>.size)
    if CMIOObjectGetPropertyData(device, &nameProp, 0, nil, nameSize, &nameSize, &name) == kCMIOHardwareNoError {
        if let deviceName = name?.takeRetainedValue() as String? {
            print("  Device: \(deviceName)")
            if deviceName.contains("GigE") {
                print("  ✅ GigE Virtual Camera found!")
            }
        }
    }
}
EOF

swift /tmp/check_cmio.swift 2>/dev/null || echo "   Failed to check CMIO devices"

# 5. Manual trigger suggestion
echo ""
echo "5. To force extension to start streaming:"
echo "   a) In Photo Booth: Switch to FaceTime camera"
echo "   b) Switch back to 'GigE Virtual Camera'"
echo "   c) The extension should log 'Stream started' when activated"

# 6. Watch for any extension activity
echo ""
echo "6. Monitoring for ANY extension logs (10 seconds)..."
PID=$(ps aux | grep GigECameraExtension | grep -v grep | awk '{print $2}')
if [[ -n "$PID" ]]; then
    # Use caffeinate to prevent timeout
    caffeinate -t 10 log stream --predicate "processID == $PID" --style compact 2>/dev/null || echo "   No logs detected"
fi