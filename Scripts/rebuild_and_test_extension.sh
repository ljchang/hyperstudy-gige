#!/bin/bash

echo "=== Rebuilding and Testing Extension with Debug Output ==="
echo ""

# Kill all processes
echo "1. Killing all processes..."
pkill -f GigEVirtualCamera.app || true
pkill -f GigECameraExtension || true
pkill -f "Photo Booth" || true
sleep 2

# Clear everything
echo "2. Clearing all data..."
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true
rm -rf "$HOME/Library/Group Containers/S368GH6KF7.com.lukechang.GigEVirtualCamera" 2>/dev/null || true

# Build the project
echo "3. Building project..."
cd /Users/lukechang/Github/hyperstudy-gige
xcodebuild -project GigEVirtualCamera.xcodeproj -scheme GigEVirtualCamera -configuration Debug clean build 2>&1 | tail -20

# Check build result
if [ -d "build/Debug/GigEVirtualCamera.app" ]; then
    echo "✅ Build succeeded"
else
    echo "❌ Build failed!"
    exit 1
fi

# Install the app
echo ""
echo "4. Installing app to /Applications..."
rm -rf /Applications/GigEVirtualCamera.app 2>/dev/null || true
cp -R build/Debug/GigEVirtualCamera.app /Applications/

# Start console log capture
echo ""
echo "5. Starting console log capture..."
LOGFILE="/tmp/extension_debug_$$.log"
log stream --predicate 'eventMessage CONTAINS "🔴" OR eventMessage CONTAINS "🟡" OR eventMessage CONTAINS "🟢" OR eventMessage CONTAINS "🔵" OR eventMessage CONTAINS "🎯" OR eventMessage CONTAINS "SharedMemoryFramePool"' > "$LOGFILE" 2>&1 &
LOGPID=$!

# Open the app to trigger extension installation
echo ""
echo "6. Opening app..."
open /Applications/GigEVirtualCamera.app
sleep 3

echo ""
echo "7. Please click 'Install Extension' in the app if prompted..."
echo "   Waiting 15 seconds for extension installation..."
sleep 15

# Open Photo Booth to load extension
echo ""
echo "8. Opening Photo Booth to trigger extension loading..."
open -a "Photo Booth"
sleep 5

# Stop log capture
kill $LOGPID 2>/dev/null

# Show captured debug output
echo ""
echo "9. Extension Debug Output:"
echo "========================="
cat "$LOGFILE" 2>/dev/null | grep -v "^Filtering" | head -50
echo "========================="

# Check shared data
echo ""
echo "10. Checking shared IOSurface IDs:"
SHARED_DATA=$(defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null)
if echo "$SHARED_DATA" | grep -q "IOSurfaceIDs"; then
    echo "✅ IOSurface IDs found in shared data:"
    echo "$SHARED_DATA" | grep -A 5 "IOSurfaceIDs"
else
    echo "❌ No IOSurface IDs found in shared data!"
    echo "Current shared data:"
    echo "$SHARED_DATA"
fi

# Cleanup
rm -f "$LOGFILE"

echo ""
echo "11. Summary:"
if echo "$SHARED_DATA" | grep -q "IOSurfaceIDs"; then
    echo "✅ Extension successfully created and shared IOSurface IDs"
    echo "Next: Try connecting to camera in the app to test frame flow"
else
    echo "❌ Extension did not share IOSurface IDs"
    echo "Check the debug output above for clues"
fi