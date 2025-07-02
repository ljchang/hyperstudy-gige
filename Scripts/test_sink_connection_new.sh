#!/bin/bash

echo "=== Testing Sink Stream Connection ==="
echo
echo "Instructions:"
echo "1. Make sure GigEVirtualCamera.app is running"
echo "2. Click 'Test Sink Stream Connection' in the app"
echo "3. Open Photo Booth and select 'GigE Virtual Camera'"
echo "4. Watch the logs below"
echo
echo "Starting log monitoring..."
echo

# Monitor logs for connection attempts
log stream --predicate 'process == "GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --style compact | grep -E "queue|Queue|sink|Sink|stream|Stream|connect|frame|Frame" | grep -v "Dropping frame"