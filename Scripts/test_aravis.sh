#!/bin/bash

# Test Aravis functionality
echo "🔍 Testing Aravis integration..."

# Check if Aravis is installed
if ! command -v arv-camera-test-0.8 &> /dev/null; then
    echo "❌ Aravis not installed. Installing..."
    brew install aravis
fi

echo ""
echo "📷 Discovering GigE cameras with Aravis..."
arv-tool-0.8 -n ".*" info

echo ""
echo "📋 Listing available cameras..."
arv-camera-test-0.8 --list-devices

echo ""
echo "🎥 Testing camera (first found)..."
arv-camera-test-0.8 -n 5 2>/dev/null || echo "No camera found or test failed"

echo ""
echo "✅ Aravis test complete"