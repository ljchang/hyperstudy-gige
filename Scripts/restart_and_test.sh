#!/bin/bash

echo "=== Restarting Everything ==="
echo

# 1. Kill everything
echo "1. Stopping apps..."
killall GigEVirtualCamera 2>/dev/null
killall FaceTime 2>/dev/null
sleep 1

# 2. Restart extension manager
echo "2. Restarting camera services..."
sudo killall -9 cmioextensionmanagerd
sleep 2

# 3. Start the GigE app
echo "3. Starting GigE Virtual Camera app..."
open /Applications/GigEVirtualCamera.app

echo "4. Wait for camera to connect..."
sleep 5

# 5. Start FaceTime
echo "5. Starting FaceTime..."
open -a FaceTime

echo
echo "6. In FaceTime:"
echo "   - Go to Video menu > Camera"
echo "   - Select 'GigE Virtual Camera'"
echo
echo "7. If still showing wrong feed:"
echo "   - In GigE app: Toggle 'Hide Preview' / 'Show Preview'"
echo "   - In GigE app: Select 'None' then reselect your camera"
echo
echo "Monitoring logs..."
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --style compact