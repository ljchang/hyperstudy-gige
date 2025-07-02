#!/bin/bash

echo "Testing GigECameraManager Delegate Fix"
echo "======================================"
echo ""
echo "1. Starting the app..."
open /Applications/GigEVirtualCamera.app

echo "2. Waiting for app to initialize..."
sleep 5

echo "3. Monitoring for delegate calls..."
echo ""
echo "Looking for:"
echo "  - 'Set aravisBridge delegate' (delegate assignment)"
echo "  - 'didReceiveFrame called' (delegate method invoked)"
echo "  - 'Distributing frame' (frame handlers called)"
echo "  - 'Wrote frame' (IOSurface writer)"
echo ""

# Monitor logs
log stream --predicate 'process == "GigEVirtualCamera"' | grep -E "(aravisBridge delegate|didReceiveFrame called|Distributing frame|Wrote frame)" &

# Save the PID
LOG_PID=$!

echo "Monitoring logs (press Ctrl+C to stop)..."
echo ""

# Wait for user to stop
trap "kill $LOG_PID 2>/dev/null; exit" INT
wait