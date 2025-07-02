#!/bin/bash

echo "=== Checking IOSurface Frame Flow ==="
echo

# Check if app is running
echo "1. Checking if GigEVirtualCamera app is running:"
pgrep -fl GigEVirtualCamera

echo
echo "2. Checking recent app logs for frame writes:"
log show --predicate 'process == "GigEVirtualCamera" AND eventMessage CONTAINS "IOSurface"' --last 30s 2>/dev/null | grep "IOSurface" | tail -5

echo
echo "3. Checking recent extension logs for frame reads:"
log show --predicate 'process == "GigECameraExtension" AND eventMessage CONTAINS[cd] "frame"' --last 30s 2>/dev/null | tail -10

echo
echo "4. Checking if Photo Booth is connected:"
ps aux | grep -i "photo booth" | grep -v grep

echo
echo "5. Monitoring live logs (press Ctrl+C to stop):"
echo "App writes (IOSurfaceFrameWriter):"
log stream --process GigEVirtualCamera --level info 2>/dev/null | grep -E "IOSurface|Frame|📤" &
APP_PID=$!

echo "Extension reads (FrameCache):"
log stream --process GigECameraExtension --level info 2>/dev/null | grep -E "Cache|Frame|📥|📤" &
EXT_PID=$!

# Wait for user to press Ctrl+C
trap "kill $APP_PID $EXT_PID 2>/dev/null; exit" INT
wait