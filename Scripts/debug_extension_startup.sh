#!/bin/bash

echo "=== Debugging Extension Startup and IOSurface Sharing ==="
echo "Date: $(date)"
echo ""

# Kill any existing processes
echo "1. Killing existing processes..."
pkill -f GigEVirtualCamera.app || true
pkill -f GigECameraExtension || true
sleep 2

# Clear app group data
echo "2. Clearing shared App Group data..."
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true

# Start monitoring logs BEFORE starting anything
echo "3. Starting log monitor..."
LOGFILE="/tmp/extension_startup_$$.log"
log stream --predicate 'subsystem CONTAINS "GigEVirtualCamera"' --info > "$LOGFILE" 2>&1 &
LOGPID=$!

# Wait a moment for log stream to start
sleep 1

# Open Photo Booth to trigger extension loading
echo "4. Opening Photo Booth to trigger extension loading..."
open -a "Photo Booth"
sleep 3

# Now start the app
echo "5. Starting GigEVirtualCamera app..."
open /Applications/GigEVirtualCamera.app
sleep 5

# Stop log capture
kill $LOGPID 2>/dev/null

# Analyze the startup sequence
echo ""
echo "6. Startup Sequence Analysis:"
echo ""

echo "Extension Initialization:"
grep -E "(SharedMemoryFramePool: Initializing|Created IOSurface|Shared IOSurface IDs)" "$LOGFILE" | head -10 | sed 's/^/  /'

echo ""
echo "App IOSurface Discovery:"
grep -E "(IOSurfaceFrameWriter initialized|Discovered.*IOSurface IDs|No IOSurface IDs)" "$LOGFILE" | head -10 | sed 's/^/  /'

echo ""
echo "Debug Timestamps:"
grep -E "(Debug_PoolInit|Debug_ProviderInit)" "$LOGFILE" | head -5 | sed 's/^/  /'

# Check final state
echo ""
echo "7. Final App Group State:"
PLIST="$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist"
if [ -f "$PLIST" ]; then
    echo "  IOSurface IDs: $(defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera IOSurfaceIDs 2>/dev/null || echo 'Not found')"
    echo "  Debug_PoolInit: $(defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera Debug_PoolInit 2>/dev/null || echo 'Not found')"
else
    echo "  App Group preferences file not found!"
fi

# Check if extension is running
echo ""
echo "8. Extension Process:"
ps aux | grep GigECameraExtension | grep -v grep | sed 's/^/  /'

# Cleanup
rm -f "$LOGFILE"

echo ""
echo "9. Diagnosis:"
echo "  - Extension should create IOSurfaces and share IDs on startup"
echo "  - App should discover these IDs when IOSurfaceFrameWriter initializes"
echo "  - If IDs aren't shared, extension may not be initializing SharedMemoryFramePool"