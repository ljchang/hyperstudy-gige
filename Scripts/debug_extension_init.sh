#!/bin/bash

echo "=== Debugging Extension Initialization ==="
echo ""

# Kill the extension to force a restart
echo "1. Forcing extension restart..."
pid=$(pgrep GigECameraExtension)
if [ ! -z "$pid" ]; then
    echo "Killing extension process: $pid"
    sudo kill -9 $pid
    sleep 2
fi

# Trigger extension start by listing cameras
echo ""
echo "2. Triggering extension start..."
system_profiler SPCameraDataType > /dev/null 2>&1

sleep 2

# Now check logs
echo ""
echo "3. Extension initialization logs (last 30 seconds):"
log stream --predicate 'subsystem contains "com.lukechang.GigEVirtualCamera.Extension"' --style compact &
LOG_PID=$!

# Let it run for a few seconds
sleep 5

# Kill the log stream
kill $LOG_PID 2>/dev/null

echo ""
echo "4. Checking if virtual camera is visible to system:"
system_profiler SPCameraDataType | grep -A3 "GigE"