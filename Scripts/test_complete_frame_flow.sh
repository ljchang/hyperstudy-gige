#!/bin/bash

echo "=== Testing Complete Frame Flow ==="
echo
echo "Architecture:"
echo "1. App captures from GigE camera (Aravis)"
echo "2. App writes to CMSimpleQueue (legacy CMIO API)"
echo "3. System bridges to extension's sink stream"
echo "4. Extension forwards frames to source stream"
echo "5. Photo Booth receives frames"
echo
echo "Steps:"
echo "1. Launch GigEVirtualCamera app"
echo "2. Click 'Test Sink Stream Connection'"
echo "3. Open Photo Booth"
echo "4. Select 'GigE Virtual Camera'"
echo "5. You should see the GigE camera feed!"
echo
echo "Starting log monitoring..."
echo

# Open the app
open /Applications/GigEVirtualCamera.app

# Wait a moment
sleep 2

# Open Photo Booth
open -a "Photo Booth"

# Monitor logs
log stream --predicate '(subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension") AND (message CONTAINS "frame" OR message CONTAINS "Frame" OR message CONTAINS "queue" OR message CONTAINS "Queue" OR message CONTAINS "sink" OR message CONTAINS "Sink" OR message CONTAINS "consume")' --style compact | grep -v "Dropping frame"