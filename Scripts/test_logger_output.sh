#!/bin/bash

echo "Testing logger output..."
echo ""

# Kill the app
killall GigEVirtualCamera 2>/dev/null
sleep 1

# Start monitoring logs BEFORE starting the app
echo "Starting log monitor..."
log stream --predicate 'process == "GigEVirtualCamera"' --level debug &
LOG_PID=$!

sleep 2

# Start the app
echo "Starting app..."
open /Applications/GigEVirtualCamera.app

# Wait a bit and then kill the log monitor
sleep 10
kill $LOG_PID 2>/dev/null

echo ""
echo "Done."