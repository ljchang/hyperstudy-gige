#!/bin/bash

echo "=== Debugging CMIO Sink Connection ==="
echo ""

# Check if app is trying to connect to sink
echo "1. Recent sink connection attempts:"
log show --style syslog --last 2m 2>/dev/null | grep -i "CMIOSinkConnector" | grep -E "(Attempting|Found|Failed|Success|Error)" | tail -10

echo ""
echo "2. Check if virtual camera device is found:"
log show --style syslog --last 2m 2>/dev/null | grep -i "GigE Virtual Camera" | grep -i "device" | tail -5

echo ""
echo "3. Stream discovery results:"
./Scripts/test_cmio_streams.sh 2>/dev/null | grep -A 5 "4B59CDEF"

echo ""
echo "4. Extension stream activity:"
log show --style syslog --last 1m 2>/dev/null | grep -E "(startStream|stopStream|Client connected|streamActive)" | grep -i "extension" | tail -10

echo ""
echo "5. Current App Group state:"
PLIST="$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist"
if [ -f "$PLIST" ]; then
    plutil -p "$PLIST" 2>/dev/null | grep -E "(StreamState|streamActive)"
fi

echo ""
echo "6. Testing manual sink discovery..."
cat > /tmp/find_sink.swift << 'EOF'
import CoreMediaIO
import Foundation

// Find GigE Virtual Camera
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

for deviceID in deviceIDs {
    prop.mSelector = CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID)
    var nameSize: UInt32 = 0
    CMIOObjectGetPropertyDataSize(deviceID, &prop, 0, nil, &nameSize)
    
    var name: CFString = "" as CFString
    CMIOObjectGetPropertyData(deviceID, &prop, 0, nil, nameSize, &nameSize, &name)
    
    if (name as String).contains("GigE") || (name as String).contains("4B59CDEF") {
        print("Found device: \(name) (ID: \(deviceID))")
        
        // Get streams
        prop.mSelector = CMIOObjectPropertySelector(kCMIODevicePropertyStreams)
        CMIOObjectGetPropertyDataSize(deviceID, &prop, 0, nil, &dataSize)
        
        let streamCount = Int(dataSize) / MemoryLayout<CMIOStreamID>.size
        var streamIDs = Array(repeating: CMIOStreamID(0), count: streamCount)
        CMIOObjectGetPropertyData(deviceID, &prop, 0, nil, dataSize, &dataSize, &streamIDs)
        
        print("  Streams: \(streamIDs)")
        
        if streamCount > 0 {
            print("  Attempting to get buffer queue for stream \(streamIDs[0])...")
            
            var queueUnmanaged: Unmanaged<CMSimpleQueue>?
            let result = CMIOStreamCopyBufferQueue(
                streamIDs[0],
                { _, _, _ in },
                nil,
                &queueUnmanaged
            )
            
            if result == kCMIOHardwareNoError {
                print("  ✓ Successfully got buffer queue!")
            } else {
                print("  ✗ Failed to get buffer queue: \(result)")
            }
        }
    }
}
EOF

swift /tmp/find_sink.swift 2>&1
rm -f /tmp/find_sink.swift