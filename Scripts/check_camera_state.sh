#!/bin/bash

echo "=== Camera State Check ==="
echo ""

# Check recent camera activity
echo "1. Camera Connection Status (last 30 seconds):"
log stream --predicate 'process == "GigEVirtualCamera" AND (message CONTAINS "camera" OR message CONTAINS "Camera" OR message CONTAINS "connected" OR message CONTAINS "streaming")' --style compact 2>/dev/null &
PID=$!
sleep 3
kill $PID 2>/dev/null
wait $PID 2>/dev/null

echo ""
echo "2. Frame Sender Connection Attempts:"
log stream --predicate 'process == "GigEVirtualCamera" AND (message CONTAINS "CMIOFrameSender" OR message CONTAINS "sink stream" OR message CONTAINS "Periodic retry")' --style compact 2>/dev/null &
PID=$!
sleep 3
kill $PID 2>/dev/null
wait $PID 2>/dev/null