#!/bin/bash

echo "=== Debugging App Connection to Virtual Camera ==="
echo ""

# Kill and restart the app with console output
echo "1. Restarting app..."
pkill -f GigEVirtualCamera
sleep 1

# Start the app and capture output
echo "2. Starting app and monitoring connection..."
/Applications/GigEVirtualCamera.app/Contents/MacOS/GigEVirtualCamera 2>&1 | grep -E "(CMIOFrameSender|connect|Connect|device|Device|sink|Sink|Found|found)" &
APP_PID=$!

# Give it time to start
sleep 5

# Check if frames are being generated
echo ""
echo "3. Checking if frames are being generated..."
ps aux | grep -i GigEVirtualCamera | grep -v grep

# Kill the grep process
kill $APP_PID 2>/dev/null || true

echo ""
echo "4. To see live output, run:"
echo "   /Applications/GigEVirtualCamera.app/Contents/MacOS/GigEVirtualCamera"