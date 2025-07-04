#!/bin/bash

echo "=== Testing Nil Checks in Extension ===="
echo ""

# Clear previous logs
echo "Clearing previous logs..."
log show --last 1s > /dev/null 2>&1

echo "Starting log monitoring..."
echo ""

# Monitor all our debug logs
log stream --predicate '
    process == "GigECameraExtension" AND 
    (eventMessage CONTAINS "sourceStreamSource exists" OR
     eventMessage CONTAINS "sourceStreamSource is NIL" OR
     eventMessage CONTAINS "ENTERED SourceStreamSource" OR
     eventMessage CONTAINS "stream is NIL" OR
     eventMessage CONTAINS "call completed" OR
     eventMessage CONTAINS "❌")
' --style compact &

MONITOR_PID=$!

echo "Log monitoring started (PID: $MONITOR_PID)"
echo "Please ensure:"
echo "1. The GigEVirtualCamera app is running"
echo "2. A camera is connected and streaming"
echo "3. Photo Booth is open and the GigE Virtual Camera is selected"
echo ""
echo "Press Ctrl+C to stop monitoring..."

# Wait for user to stop
wait $MONITOR_PID