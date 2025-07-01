#!/bin/bash

echo "=== Testing GigE Camera Discovery ==="
echo

# 1. Kill any existing app instances
echo "1. Killing existing app instances..."
killall GigEVirtualCamera 2>/dev/null || echo "No existing instances found"

# 2. Run the app with debug output
echo
echo "2. Starting app with verbose logging..."
echo "Running: /Applications/GigEVirtualCamera.app/Contents/MacOS/GigEVirtualCamera"
echo
echo "Look for:"
echo "- 'Discovering cameras...' messages"
echo "- 'Found X cameras' messages"
echo "- Any error messages"
echo
echo "Press Ctrl+C to stop"
echo

# Run with environment variable for verbose logging
ARAVIS_DEBUG=all /Applications/GigEVirtualCamera.app/Contents/MacOS/GigEVirtualCamera