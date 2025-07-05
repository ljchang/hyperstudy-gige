#!/bin/bash

echo "=== GigE Camera Connection Diagnostics ==="
echo

# Check if camera is visible to Aravis
echo "1. Checking Aravis camera discovery..."
arv-tool-0.8
echo

# Monitor app logs
echo "2. Monitoring camera connection logs..."
echo "   (Try selecting the camera in the app)"
echo

log stream --predicate '
    subsystem == "com.lukechang.GigEVirtualCamera" AND 
    (eventMessage CONTAINS "CameraManager" OR 
     eventMessage CONTAINS "GigECameraManager" OR 
     eventMessage CONTAINS "AravisBridge" OR
     eventMessage CONTAINS "connect" OR
     eventMessage CONTAINS "Connect" OR
     eventMessage CONTAINS "camera" OR
     eventMessage CONTAINS "Camera")
' --level debug | grep -E "connect|Connect|camera|Camera|error|Error|fail|Fail" --color=always