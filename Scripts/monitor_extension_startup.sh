#!/bin/bash

echo "Monitoring extension startup..."
echo "Please select 'GigE Virtual Camera' in Photo Booth NOW!"
echo ""

# Monitor for extension process starting
while true; do
    if pgrep -f "GigEVirtualCameraExtension" > /dev/null; then
        echo "✅ Extension process started!"
        break
    fi
    sleep 0.5
done

# Once started, monitor logs
echo ""
echo "Extension is running, monitoring logs..."
log stream --predicate '
    process == "GigEVirtualCameraExtension" OR 
    subsystem == "com.lukechang.GigEVirtualCamera" OR
    eventMessage CONTAINS "CMIOPropertyListener" OR
    eventMessage CONTAINS "sink" OR
    eventMessage CONTAINS "stream"
' --info