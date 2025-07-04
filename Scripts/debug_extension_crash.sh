#!/bin/bash

echo "=== Debugging Extension Crash ==="
echo ""

# Clean start
echo "1. Killing existing processes..."
killall GigEVirtualCamera 2>/dev/null
killall GigECameraExtension 2>/dev/null
killall "Photo Booth" 2>/dev/null
sleep 2

# Check app group permissions
echo ""
echo "2. Checking App Group access..."
APPGROUP_PATH="$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera"
if [ -d "$APPGROUP_PATH" ]; then
    echo "✅ App Group directory exists"
    ls -la "$APPGROUP_PATH/Library/Preferences/" 2>/dev/null | grep plist
else
    echo "❌ App Group directory NOT found"
fi

# Start the app
echo ""
echo "3. Starting GigEVirtualCamera app..."
open /Users/lukechang/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-gwoebjnyoldbeyedqrzcrnlowqcw/Build/Products/Debug/GigEVirtualCamera.app
sleep 3

# Monitor for extension
echo ""
echo "4. Opening Photo Booth and monitoring extension..."
open -a "Photo Booth"

# Clear console and monitor
echo ""
echo "5. Monitoring extension lifecycle..."
echo "Select 'GigE Virtual Camera' in Photo Booth now!"
echo ""

# Monitor in real-time
log stream --predicate '
    process == "GigECameraExtension" OR 
    process == "kernel" OR
    (subsystem == "com.lukechang.GigEVirtualCamera.Extension") OR
    (eventMessage CONTAINS "GigECameraExtension") OR
    (eventMessage CONTAINS "terminated") OR
    (eventMessage CONTAINS "crash")
' --info --style compact | while read line; do
    # Highlight important messages
    if echo "$line" | grep -q "🔴"; then
        echo "🎯 EXTENSION: $line"
    elif echo "$line" | grep -q -E "terminated|crash|exit|died"; then
        echo "💥 CRASH: $line"
    elif echo "$line" | grep -q "started"; then
        echo "✅ START: $line"
    else
        echo "$line"
    fi
done