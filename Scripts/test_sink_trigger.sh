#!/bin/bash

echo "=== Testing Sink Stream Trigger ==="
echo ""

# First, manually set the stream state to trigger the app
echo "1. Manually triggering stream state..."
defaults write ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist StreamState -dict streamActive -bool true timestamp -float $(date +%s) pid -int $$

echo "2. Verifying stream state was set..."
defaults read ~/Library/Group\ Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist StreamState

echo ""
echo "3. Monitoring app response for 5 seconds..."
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND eventMessage CONTAINS "stream"' --style compact &
LOG_PID=$!

sleep 5
kill $LOG_PID 2>/dev/null

echo ""
echo "4. Checking if frames are being sent..."
log show --last 10s --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "CMIOSinkConnector" AND eventMessage CONTAINS "frame"' | head -10

echo ""
echo "Done. Check if the app started sending frames to the sink."