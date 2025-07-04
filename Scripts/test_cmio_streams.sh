#!/bin/bash

echo "=== Testing CMIO Stream Discovery ==="
echo ""

# Simple C program to list CMIO devices and streams
cat > /tmp/test_cmio.c << 'EOF'
#include <CoreMediaIO/CMIOHardware.h>
#include <stdio.h>

int main() {
    // Get all devices
    CMIOObjectPropertyAddress prop = {
        kCMIOHardwarePropertyDevices,
        kCMIOObjectPropertyScopeGlobal,
        kCMIOObjectPropertyElementMain
    };
    
    UInt32 dataSize = 0;
    OSStatus status = CMIOObjectGetPropertyDataSize(kCMIOObjectSystemObject, &prop, 0, NULL, &dataSize);
    if (status != kCMIOHardwareNoError) {
        printf("Error getting device list size\n");
        return 1;
    }
    
    int deviceCount = dataSize / sizeof(CMIODeviceID);
    CMIODeviceID devices[deviceCount];
    
    UInt32 dataUsed = 0;
    status = CMIOObjectGetPropertyData(kCMIOObjectSystemObject, &prop, 0, NULL, dataSize, &dataUsed, devices);
    if (status != kCMIOHardwareNoError) {
        printf("Error getting device list\n");
        return 1;
    }
    
    printf("Found %d CMIO devices:\n\n", deviceCount);
    
    // Check each device
    for (int i = 0; i < deviceCount; i++) {
        // Get device name
        prop.mSelector = kCMIODevicePropertyDeviceUID;
        CMIOObjectGetPropertyDataSize(devices[i], &prop, 0, NULL, &dataSize);
        
        CFStringRef name = NULL;
        CMIOObjectGetPropertyData(devices[i], &prop, 0, NULL, dataSize, &dataUsed, &name);
        
        if (name) {
            char buffer[256];
            CFStringGetCString(name, buffer, sizeof(buffer), kCFStringEncodingUTF8);
            printf("Device %d: %s (ID: %d)\n", i, buffer, devices[i]);
            
            // Get streams
            prop.mSelector = kCMIODevicePropertyStreams;
            CMIOObjectGetPropertyDataSize(devices[i], &prop, 0, NULL, &dataSize);
            
            int streamCount = dataSize / sizeof(CMIOStreamID);
            if (streamCount > 0) {
                CMIOStreamID streams[streamCount];
                CMIOObjectGetPropertyData(devices[i], &prop, 0, NULL, dataSize, &dataUsed, streams);
                
                printf("  Streams: %d\n", streamCount);
                for (int j = 0; j < streamCount; j++) {
                    // Get stream direction
                    prop.mSelector = kCMIOStreamPropertyDirection;
                    UInt32 direction = 0;
                    dataSize = sizeof(direction);
                    CMIOObjectGetPropertyData(streams[j], &prop, 0, NULL, dataSize, &dataUsed, &direction);
                    
                    printf("    Stream %d: ID=%d, Direction=%s\n", 
                           j, streams[j], 
                           direction == 0 ? "Output/Source" : "Input/Sink");
                }
            }
            printf("\n");
            
            CFRelease(name);
        }
    }
    
    return 0;
}
EOF

echo "Compiling CMIO test tool..."
clang -framework CoreMediaIO -framework CoreFoundation -o /tmp/test_cmio /tmp/test_cmio.c

if [ $? -eq 0 ]; then
    echo "Running CMIO device/stream discovery..."
    echo ""
    /tmp/test_cmio
else
    echo "Failed to compile test tool"
fi

# Cleanup
rm -f /tmp/test_cmio /tmp/test_cmio.c