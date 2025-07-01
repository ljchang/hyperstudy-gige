#!/bin/bash

echo "=== Trigger Frame Sender Reconnect ==="
echo
echo "The CMIOFrameSender needs to reconnect to the virtual camera."
echo
echo "In the GigE Virtual Camera app:"
echo "1. Select 'None' from the camera dropdown"
echo "2. Wait 2 seconds"
echo "3. Select your camera again"
echo
echo "This will trigger CameraManager to call setupFrameSender() again"
echo "and attempt to connect to the virtual camera device."
echo
echo "Monitor the logs with:"
echo "log stream --predicate 'process == \"GigEVirtualCamera\"' | grep -i \"device\\|found\\|searching\""