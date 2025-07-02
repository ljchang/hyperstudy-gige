#!/bin/bash

echo "=== Tracing Extension Initialization ==="
echo ""

# Kill extension
pkill -f GigECameraExtension
sleep 2

# Clear data
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true

# Start dtrace to monitor extension startup (requires sudo)
echo "Starting trace (may require password)..."
sudo dtrace -n 'proc:::start /execname == "GigECameraExtension"/ { printf("Extension started PID %d\n", pid); }' &
DTRACE_PID=$!

# Open Photo Booth
echo "Opening Photo Booth..."
open -a "Photo Booth"
sleep 5

# Kill dtrace
sudo kill $DTRACE_PID 2>/dev/null

# Check if extension created any files
echo ""
echo "Checking for extension activity..."
echo ""
echo "1. Process info:"
ps aux | grep GigECameraExtension | grep -v grep

echo ""
echo "2. App group data:"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || echo "No data written"

echo ""
echo "3. Recent file modifications in app group:"
find "$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera" -type f -mtime -1 -ls 2>/dev/null

echo ""
echo "4. Checking if extension loaded our classes:"
# Use sample to check if SharedMemoryFramePool is in memory
EXTENSION_PID=$(ps aux | grep GigECameraExtension | grep -v grep | awk '{print $2}')
if [ -n "$EXTENSION_PID" ]; then
    echo "Sampling extension (PID $EXTENSION_PID)..."
    sample $EXTENSION_PID 1 2>&1 | grep -E "(SharedMemoryFramePool|GigEVirtualCameraExtensionProvider|FrameCoordinator)" | head -10
fi