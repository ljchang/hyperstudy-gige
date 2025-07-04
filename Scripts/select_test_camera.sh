#!/bin/bash

echo "=== Simulating Test Camera Selection ==="
echo ""

# First, check if the test camera is in the list
echo "1. Checking for available cameras..."
defaults read com.lukechang.GigEVirtualCamera 2>/dev/null | grep -A5 "lastConnectedCamera"

echo ""
echo "2. Writing test camera selection to UserDefaults..."
# Set the test camera as selected
defaults write com.lukechang.GigEVirtualCamera lastConnectedCamera "Test Camera (Aravis Simulator)"

echo ""
echo "3. Triggering camera discovery..."
# Write a marker to trigger discovery
defaults write group.S368GH6KF7.com.lukechang.GigEVirtualCamera TriggerDiscovery -bool YES
defaults synchronize

echo ""
echo "4. Camera selection complete. Monitor logs for connection..."
echo ""
echo "To monitor connection:"
echo "log stream --predicate 'process == \"GigEVirtualCamera\" AND eventMessage CONTAINS \"connect\"' --style compact"