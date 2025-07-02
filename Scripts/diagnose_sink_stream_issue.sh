#!/bin/bash

echo "=== Diagnosing Sink Stream Issue ==="
echo
echo "The problem: Frames are being sent to the sink stream queue but not consumed by the extension"
echo
echo "Checking key indicators..."
echo

# 1. Check if extension is receiving the consumeSampleBuffer calls
echo "1. Looking for sink stream consume calls in extension:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND message CONTAINS "consume"' --last 2m | tail -10

echo
echo "2. Looking for sink stream activity:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND message CONTAINS "Sink"' --last 2m | tail -10

echo
echo "3. Checking if Photo Booth actually started the sink stream:"
log show --predicate 'process == "Photo Booth" AND message CONTAINS "sink"' --last 2m | tail -10

echo
echo "4. The issue appears to be:"
echo "   - Photo Booth starts the SOURCE stream (to receive frames)"
echo "   - But it doesn't start the SINK stream (to send frames to extension)"
echo "   - The app tries to send frames to a sink stream that isn't consuming"
echo
echo "5. Possible solutions:"
echo "   a) The sink stream might need to be explicitly started by the extension"
echo "   b) The queue might be created but not actively consumed"
echo "   c) There might be a timing issue with queue creation"
echo
echo "Try this:"
echo "   1. In Photo Booth, make sure the camera is selected AND recording/preview is active"
echo "   2. Click 'Test Sink Stream Connection' button in the app AFTER Photo Booth is recording"