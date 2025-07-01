#!/bin/bash

# Monitor system extension installation for GigE Virtual Camera

echo "=== Monitoring System Extension Installation ==="
echo "Click 'Install Extension' in the app if you haven't already"
echo "Press Ctrl+C to stop monitoring"
echo

while true; do
    clear
    echo "=== System Extensions Status ==="
    systemextensionsctl list
    
    echo
    echo "=== CMIO Devices ==="
    system_profiler SPCameraDataType | grep -A5 "GigE Virtual Camera" || echo "Virtual camera not found yet"
    
    echo
    echo "=== Recent Logs ==="
    log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' --last 10s --style compact | tail -10
    
    echo
    echo "If you see 'needs user approval', go to:"
    echo "System Settings > Privacy & Security > General"
    echo
    echo "Refreshing in 3 seconds..."
    sleep 3
done