#!/bin/bash

echo "=== Restarting Frame Flow ==="
echo ""

# Kill all processes
echo "1. Stopping all processes..."
pkill -f GigEVirtualCamera.app || true
pkill -f GigECameraExtension || true
pkill -f "Photo Booth" || true
sleep 2

# Clear shared data
echo "2. Clearing shared data..."
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true

# Start the app
echo "3. Starting GigEVirtualCamera app..."
open /Applications/GigEVirtualCamera.app
sleep 3

# Open Photo Booth
echo "4. Opening Photo Booth..."
open -a "Photo Booth"
sleep 3

echo "5. Please do the following:"
echo "   - In the app: Make sure 'Test Camera' is selected and connected"
echo "   - In Photo Booth: Select 'GigE Virtual Camera'"
echo ""
echo "6. Monitoring frame flow..."
echo ""

# Monitor both sides
echo "APP WRITES                                    | EXTENSION READS"
echo "============================================ | ============================================"

# Start monitoring in background
(log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "IOSurfaceFrameWriter"' --info --style compact | grep "Wrote frame" | while read line; do echo "$line" | cut -c1-44; done) &
PID1=$!

(log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --info --style compact | grep -E "(New frame|Checking frame|Frame #)" | while read line; do echo -e "\r\033[45C| $line" | cut -c1-90; done) &
PID2=$!

# Let it run
sleep 30

# Cleanup
kill $PID1 $PID2 2>/dev/null

echo ""
echo ""
echo "7. Final check:"
plutil -p "$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist" 2>/dev/null | grep -E "(IOSurfaceIDs|CurrentFrameIndex)" | head -10