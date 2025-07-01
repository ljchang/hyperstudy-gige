#!/bin/bash

echo "=== CMIO Extension Debug Info ==="

# Check if extension is installed
echo -e "\n1. System Extensions:"
systemextensionsctl list

# Check CMIO extensions
echo -e "\n2. CMIO Extensions (via registerassistantservice):"
ps aux | grep -i registerassistant | grep -v grep

# Check if our specific extension is running
echo -e "\n3. GigE Virtual Camera Extension Process:"
ps aux | grep -i "GigEVirtualCamera" | grep -v grep

# Check system logs for CMIO extension
echo -e "\n4. Recent CMIO Extension Logs:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 5m --info --debug

# Check for extension in camera list
echo -e "\n5. System Camera List:"
system_profiler SPCameraDataType

# Check for CMIO device registrations
echo -e "\n6. CMIO Device Registrations:"
log show --predicate 'eventMessage CONTAINS "CMIO" OR subsystem CONTAINS "coremedia"' --last 5m --info | grep -i "gige\|virtual"

# Check launchd status
echo -e "\n7. Launchd Status for Extension:"
launchctl list | grep -i "gige\|cmio"

# Check if extension bundle exists
echo -e "\n8. Extension Bundle Check:"
EXTENSION_PATH="/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigEVirtualCameraExtension.systemextension"
if [ -d "$EXTENSION_PATH" ]; then
    echo "Extension bundle found at: $EXTENSION_PATH"
    echo "Bundle contents:"
    ls -la "$EXTENSION_PATH/Contents/"
    
    echo -e "\nInfo.plist contents:"
    plutil -p "$EXTENSION_PATH/Contents/Info.plist" | grep -A2 -B2 "CMIOExtension"
else
    echo "Extension bundle NOT found at expected path: $EXTENSION_PATH"
fi

echo -e "\n=== End Debug Info ==="