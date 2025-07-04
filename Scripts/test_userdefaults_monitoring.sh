#!/bin/bash

echo "=== Testing UserDefaults Monitoring ==="
echo ""

# Check current state
echo "1. Current StreamState in App Group:"
plutil -p "$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist" 2>/dev/null | grep -A3 StreamState

echo ""
echo "2. Setting test stream state..."
defaults write "$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist" StreamState -dict streamActive -bool YES timestamp -float $(date +%s) pid -int $$

echo ""
echo "3. Monitoring app response for 5 seconds..."
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' --info | grep -E "(handleStreamStateChange|Extension requesting|Connecting to sink)" &
LOG_PID=$!

sleep 5
kill $LOG_PID 2>/dev/null

echo ""
echo "4. Clearing test state..."
defaults delete "$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist" StreamState 2>/dev/null

echo ""
echo "Done"