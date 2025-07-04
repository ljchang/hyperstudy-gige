#!/bin/bash

echo "=== Debugging Sink Connector Initialization ==="
echo ""

# First check if app is running
echo "1. App status:"
ps aux | grep GigEVirtualCamera | grep -v grep | head -1
echo ""

# Look for any sink connector logs in last 30 seconds
echo "2. Sink connector initialization (last 30s):"
log show --last 30s 2>/dev/null | grep -i "cmiosink\|sink.*connector\|manual discovery" | head -10 || echo "   No sink connector logs found"
echo ""

# Check for frame sending logs
echo "3. Frame sending status (last 30s):"
log show --last 30s 2>/dev/null | grep -i "not sending frames\|isFrameSenderConnected" | head -10 || echo "   No frame sending logs found"
echo ""

# Live monitor
echo "4. Starting live monitor..."
echo "   (Connect a camera and start streaming)"
echo ""

log stream --predicate 'eventMessage CONTAINS[c] "sink" OR eventMessage CONTAINS[c] "manual discovery" OR eventMessage CONTAINS "Not sending frames"' 2>/dev/null | head -30