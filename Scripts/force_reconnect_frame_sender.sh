#!/bin/bash

echo "=== Force Reconnect Frame Sender ==="
echo

echo "1. Current state:"
echo "   - Extension is running"
echo "   - Virtual camera is registered"
echo "   - App can't find it (timing issue)"
echo

echo "2. Solutions:"
echo "   a) Restart the app:"
killall GigEVirtualCamera 2>/dev/null
sleep 1
open /Applications/GigEVirtualCamera.app

echo
echo "   b) Or in the app:"
echo "      - Toggle camera selection (None -> Your Camera)"
echo "      - This should trigger reconnection"
echo

echo "3. The app should now find the virtual camera and start streaming!"