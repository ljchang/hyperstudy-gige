#!/bin/bash

# Test script for GigE Virtual Camera extension
set -e

echo "🔍 Testing GigE Virtual Camera Extension..."

# Check if app is in Applications
if [ ! -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "❌ App not found in /Applications"
    echo "Please copy the app to /Applications first"
    exit 1
fi

echo "✅ App found in /Applications"

# Check system extension status
echo ""
echo "📦 Current system extensions:"
systemextensionsctl list

# Check if our extension is loaded
echo ""
echo "🔍 Checking for GigE extension process:"
ps aux | grep -i gige | grep -v grep || echo "No GigE extension process found"

# Check system logs
echo ""
echo "📝 Recent system logs for GigE extension:"
log show --style compact --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 5m | tail -20

# Check if virtual camera appears
echo ""
echo "📷 Checking for virtual camera in system:"
system_profiler SPCameraDataType | grep -i "gige" || echo "No GigE virtual camera found"

# Check CMIO devices
echo ""
echo "🎥 Checking Core Media IO devices:"
log show --style compact --predicate 'process == "appleh13camerad"' --last 1m | grep -i gige || echo "No recent CMIO logs for GigE"

echo ""
echo "✅ Test complete"