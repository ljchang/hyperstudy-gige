#!/bin/bash

echo "=== Testing App Group Access ==="
echo ""

# Clear app group
echo "1. Clearing app group data..."
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true

# Write test data from command line
echo "2. Writing test data to app group..."
defaults write group.S368GH6KF7.com.lukechang.GigEVirtualCamera TestKey "TestValue"
defaults write group.S368GH6KF7.com.lukechang.GigEVirtualCamera TestArray -array 1 2 3

# Read it back
echo "3. Reading back test data:"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || echo "Failed to read"

# Check the plist file directly
echo ""
echo "4. Checking plist file:"
PLIST="$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist"
if [ -f "$PLIST" ]; then
    echo "Plist exists at: $PLIST"
    ls -la "$PLIST"
else
    echo "Plist file not found!"
fi

# Kill and restart extension
echo ""
echo "5. Restarting extension..."
pkill -f GigECameraExtension
sleep 2
open -a "Photo Booth"
sleep 5

# Check if extension wrote anything
echo ""
echo "6. Checking if extension wrote data:"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || echo "No data from extension"

# Check console for any errors
echo ""
echo "7. Checking for sandbox/permission errors:"
log show --predicate 'process == "GigECameraExtension" AND (eventMessage CONTAINS "sandbox" OR eventMessage CONTAINS "deny" OR eventMessage CONTAINS "App Groups")' --last 2m 2>/dev/null | tail -10