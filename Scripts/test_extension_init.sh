#!/bin/bash

echo "=== Testing Extension Initialization ==="
echo ""

# Kill extension
echo "1. Killing extension..."
pkill -f GigECameraExtension
sleep 2

# Clear app group
echo "2. Clearing app group data..."
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true

# Start log capture
echo "3. Starting log capture..."
LOGFILE="/tmp/extension_init_$$.log"
log stream --process GigECameraExtension --info > "$LOGFILE" 2>&1 &
LOGPID=$!

# Open Photo Booth to trigger extension
echo "4. Opening Photo Booth to trigger extension..."
open -a "Photo Booth"
sleep 5

# Kill log stream
kill $LOGPID 2>/dev/null

# Check for our debug messages
echo "5. Checking for initialization messages:"
echo ""
echo "Extension startup:"
grep -E "Extension main|🔴" "$LOGFILE" 2>/dev/null | head -5

echo ""
echo "SharedMemoryFramePool init:"
grep -E "SharedMemoryFramePool|🚀|🟢" "$LOGFILE" 2>/dev/null | head -10

echo ""
echo "IOSurface creation:"
grep -E "Created IOSurface|IOSurface.*with ID" "$LOGFILE" 2>/dev/null | head -5

echo ""
echo "6. Checking app group data:"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null | grep -A 10 IOSurfaceIDs || echo "No IOSurface IDs found"

# Also check stderr/stdout
echo ""
echo "7. Checking system log for print statements:"
log show --predicate 'eventMessage CONTAINS "🔴" OR eventMessage CONTAINS "🟡" OR eventMessage CONTAINS "🟢"' --last 1m 2>/dev/null | tail -10

rm -f "$LOGFILE"