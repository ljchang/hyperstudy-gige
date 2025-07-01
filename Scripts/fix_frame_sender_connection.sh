#!/bin/bash

echo "=== Fixing Frame Sender Connection ==="
echo

# 1. Kill the app to restart it
echo "1. Stopping current app instance..."
killall GigEVirtualCamera 2>/dev/null || echo "App not running"

# 2. Kill the extension manager to force refresh
echo
echo "2. Refreshing camera extension manager..."
sudo killall -9 cmioextensionmanagerd

echo
echo "3. Wait a moment for services to restart..."
sleep 2

echo
echo "4. Start the app again..."
open /Applications/GigEVirtualCamera.app

echo
echo "5. Monitor connection attempts..."
echo "Watching logs for connection attempts..."
echo
log stream --predicate 'process == "GigEVirtualCamera" AND (message CONTAINS "CMIO" OR message CONTAINS "connect" OR message CONTAINS "sender")' --style compact