#!/bin/bash

echo "=== Force Extension Restart and Debug ==="
echo ""

# Kill all processes
echo "1. Killing all processes..."
pkill -f GigEVirtualCamera.app || true
pkill -f GigECameraExtension || true
pkill -f "Photo Booth" || true
sleep 2

# Clear shared data
echo "2. Clearing shared data..."
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true

# Remove the incorrect app group directory
echo "3. Removing incorrect app group directory..."
rm -rf "$HOME/Library/Group Containers/S368GH6KF7.com.lukechang.GigEVirtualCamera" 2>/dev/null || true

# Open Photo Booth first to load extension
echo "4. Opening Photo Booth to load extension..."
open -a "Photo Booth"
sleep 5

# Check if extension loaded and created IOSurfaces
echo "5. Checking extension status..."
ps aux | grep GigECameraExtension | grep -v grep

echo ""
echo "6. Checking shared IOSurface IDs..."
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || echo "No shared data yet"

# Now start the app
echo ""
echo "7. Starting app..."
open /Applications/GigEVirtualCamera.app
sleep 3

echo ""
echo "8. Final check of shared data..."
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null | grep -E "(IOSurfaceIDs|Debug_)" || echo "No IOSurface IDs found"

echo ""
echo "9. Testing frame flow..."
# Trigger camera connection
osascript -e 'tell application "System Events"
    tell process "GigEVirtualCamera"
        set frontmost to true
    end tell
end tell' 2>/dev/null

sleep 5

# Monitor logs briefly
echo ""
echo "10. Recent frame activity:"
log show --predicate 'eventMessage CONTAINS "IOSurface" OR eventMessage CONTAINS "frame"' --last 30s --info 2>/dev/null | grep -E "(Wrote frame|IOSurface: [0-9]+|Failed to lookup)" | tail -10