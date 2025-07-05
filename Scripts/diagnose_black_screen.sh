#!/bin/bash

echo "=== GigE Camera Black Screen Diagnostics ==="
echo "Starting at $(date)"
echo

# Monitor system logs for our app and extension
echo "1. Monitoring camera logs..."
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --level debug &
LOG_PID=$!

# Also monitor for Aravis-specific messages
echo "2. Monitoring Aravis messages..."
log stream --predicate 'eventMessage CONTAINS "Aravis" OR eventMessage CONTAINS "GigE" OR eventMessage CONTAINS "pixel" OR eventMessage CONTAINS "frame"' --level debug &
ARAVIS_PID=$!

echo
echo "Monitoring started. Press Ctrl+C to stop."
echo "Try connecting to your camera and reproducing the black screen issue..."
echo

# Wait for user to stop
trap "kill $LOG_PID $ARAVIS_PID 2>/dev/null; exit" INT
wait