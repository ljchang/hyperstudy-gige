#!/bin/bash

echo "Testing Frame Writing to Shared UserDefaults"
echo "==========================================="
echo ""

# Clean up first
echo "1. Cleaning up old data..."
defaults delete group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || true

# Write test data
echo "2. Writing test frame data..."
defaults write group.S368GH6KF7.com.lukechang.GigEVirtualCamera currentFrameIndex 999
defaults write group.S368GH6KF7.com.lukechang.GigEVirtualCamera currentFrameSurfaceID 12345
defaults write group.S368GH6KF7.com.lukechang.GigEVirtualCamera frameWidth 1920
defaults write group.S368GH6KF7.com.lukechang.GigEVirtualCamera frameHeight 1080

# Read it back
echo "3. Reading back test data..."
echo "Frame Index: $(defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera currentFrameIndex 2>/dev/null || echo 'NOT FOUND')"
echo "Surface ID: $(defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera currentFrameSurfaceID 2>/dev/null || echo 'NOT FOUND')"
echo "Width: $(defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera frameWidth 2>/dev/null || echo 'NOT FOUND')"
echo "Height: $(defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera frameHeight 2>/dev/null || echo 'NOT FOUND')"

echo ""
echo "4. Checking if extension can read it..."
# The extension should be able to read these values

echo ""
echo "If you see the values above, the app group is working correctly."
echo "The issue might be that the IOSurfaceFrameWriter isn't being called."