#!/bin/bash

echo "=== Monitoring Fixed Connection Attempt ==="
echo ""

# Wait for app to start
sleep 2

# Check if property listener finds the device and streams
echo "1. Checking property listener discovery:"
log show --last 5s --predicate 'eventMessage CONTAINS "Found virtual camera" OR eventMessage CONTAINS "Checking stream" OR eventMessage CONTAINS "Found sink stream"' --style compact | tail -20

echo ""
echo "2. Checking manual discovery:"
log show --last 5s --predicate 'eventMessage CONTAINS "manual discovery" OR eventMessage CONTAINS "Found virtual camera - device ID"' --style compact | tail -10

echo ""
echo "3. Checking sink connection attempts:"
log show --last 5s --predicate 'eventMessage CONTAINS "connect to sink stream" OR eventMessage CONTAINS "Successfully obtained buffer queue" OR eventMessage CONTAINS "Successfully connected"' --style compact | tail -10

echo ""
echo "4. Checking frame sending:"
log show --last 5s --predicate 'eventMessage CONTAINS "Cannot send frame" OR eventMessage CONTAINS "Sent frame"' --style compact | tail -10

echo ""
echo "5. Current process status:"
ps aux | grep -E "GigE" | grep -v grep