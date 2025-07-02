#!/bin/bash

echo "=== Clean Reinstall of Extension ==="
echo ""

# Kill all processes
echo "1. Killing all processes..."
pkill -f GigEVirtualCamera.app || true
pkill -f GigECameraExtension || true
pkill -f "Photo Booth" || true
sleep 2

# Uninstall all extension versions
echo "2. Uninstalling all extension versions..."
# First, get the app to uninstall its extension
open /Applications/GigEVirtualCamera.app
sleep 3

# Try to trigger uninstall via the app UI
echo "   Please click 'Uninstall Extension' in the app if visible..."
sleep 10

# Kill the app
pkill -f GigEVirtualCamera.app || true
sleep 2

# Reset system extensions
echo "3. Resetting system extensions (may require password)..."
systemextensionsctl reset
sleep 2

# Clear all data
echo "4. Clearing all data..."
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true
rm -rf "$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera" 2>/dev/null || true
rm -rf "$HOME/Library/Group Containers/S368GH6KF7.com.lukechang.GigEVirtualCamera" 2>/dev/null || true

# Rebuild
echo "5. Rebuilding project..."
cd /Users/lukechang/Github/hyperstudy-gige
xcodebuild -project GigEVirtualCamera.xcodeproj -scheme GigEVirtualCamera -configuration Debug clean build >/dev/null 2>&1

if [ -d "build/Debug/GigEVirtualCamera.app" ]; then
    echo "✅ Build succeeded"
else
    echo "❌ Build failed!"
    exit 1
fi

# Install fresh app
echo "6. Installing fresh app..."
rm -rf /Applications/GigEVirtualCamera.app 2>/dev/null || true
cp -R build/Debug/GigEVirtualCamera.app /Applications/

# Start monitoring
echo "7. Starting log monitor..."
LOGFILE="/tmp/extension_install_$$.log"
log stream --predicate 'subsystem CONTAINS "GigEVirtualCamera" OR process == "GigECameraExtension"' --info > "$LOGFILE" 2>&1 &
LOGPID=$!

# Open app
echo "8. Opening app..."
open /Applications/GigEVirtualCamera.app
sleep 3

echo "9. Please click 'Install Extension' when prompted..."
echo "   Then approve in System Settings if needed..."
echo "   Waiting 20 seconds..."
sleep 20

# Open Photo Booth
echo "10. Opening Photo Booth..."
open -a "Photo Booth"
sleep 5

# Stop log monitor
kill $LOGPID 2>/dev/null

# Check results
echo ""
echo "11. Extension Status:"
systemextensionsctl list | grep -A 2 "com.lukechang.GigEVirtualCamera" | grep -v "terminated"

echo ""
echo "12. Shared Data:"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || echo "No shared data"

echo ""
echo "13. Recent Logs:"
grep -E "(SharedMemoryFramePool|IOSurface|Created|Shared|🔴|🟡|🟢|🔵)" "$LOGFILE" 2>/dev/null | tail -20

# Cleanup
rm -f "$LOGFILE"