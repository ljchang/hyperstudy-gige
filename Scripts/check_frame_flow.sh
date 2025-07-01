#!/bin/bash

echo "=== Checking Frame Flow ==="
echo ""

# Check if both processes are running
echo "1. Process Status:"
ps aux | grep -E "(GigEVirtualCamera|GigECameraExtension)" | grep -v grep | awk '{print "   " $11}'

echo ""
echo "2. Recent Frame Activity (last 10 seconds):"

# Create a temporary file for logs
TMPFILE=$(mktemp)

# Capture logs for 5 seconds
log stream --predicate '(subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension") AND (message CONTAINS "frame" OR message CONTAINS "Frame" OR message CONTAINS "Sending" OR message CONTAINS "Received")' --style compact > "$TMPFILE" &
LOG_PID=$!

sleep 5
kill $LOG_PID 2>/dev/null

# Process the logs
echo "   App -> Extension:"
grep -i "sending frame\|enqueued frame" "$TMPFILE" | tail -5

echo ""
echo "   Extension Receiving:"
grep -i "received frame\|sink stream" "$TMPFILE" | tail -5

echo ""
echo "   Extension -> Photo Booth:"
grep -i "forwarding frame\|sending frame.*photo" "$TMPFILE" | tail -5

# Clean up
rm -f "$TMPFILE"

echo ""
echo "3. Queue Status:"
# Try to get queue status from recent logs
log show --predicate 'message CONTAINS "Queue status"' --last 30s 2>/dev/null | tail -3