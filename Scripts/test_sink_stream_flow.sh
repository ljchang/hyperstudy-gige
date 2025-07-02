#!/bin/bash

echo "=== Testing Sink Stream Frame Flow ==="
echo
echo "This test will verify that frames flow correctly:"
echo "1. App connects to GigE camera"
echo "2. App starts the device (which starts sink stream)"
echo "3. App sends frames to sink stream queue"
echo "4. Extension consumes frames from sink stream"
echo "5. Extension forwards frames to source stream"
echo "6. Photo Booth receives frames"
echo

# Kill any existing instances
killall GigEVirtualCamera 2>/dev/null
killall "Photo Booth" 2>/dev/null
sleep 1

echo "Starting GigEVirtualCamera app..."
open /Applications/GigEVirtualCamera.app

echo "Waiting for app to start..."
sleep 3

echo "Opening Photo Booth..."
open -a "Photo Booth"

echo
echo "Instructions:"
echo "1. In GigEVirtualCamera app, click 'Test Sink Stream Connection'"
echo "2. In Photo Booth, select 'GigE Virtual Camera' from camera menu"
echo "3. You should see the GigE camera feed!"
echo
echo "Monitoring logs for frame flow..."
echo "Look for:"
echo "- 'Successfully started device' (app starts device)"
echo "- 'Sink stream started' (extension starts consuming)"
echo "- 'Sink received frame' (extension receives frames)"
echo "- 'Frame #X to clients' (extension sends to Photo Booth)"
echo

# Monitor logs for frame flow
log stream --predicate '(subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension") AND (message CONTAINS "started" OR message CONTAINS "Sink" OR message CONTAINS "sink" OR message CONTAINS "Frame" OR message CONTAINS "queue")' --style compact | grep -v "Dropping frame"