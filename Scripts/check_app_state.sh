#!/bin/bash

echo "=== Checking GigE Virtual Camera App State ==="
echo ""

# Check if app is running
echo "1. App Process:"
if ps aux | grep -v grep | grep -q "GigEVirtualCamera.app"; then
    echo "✅ App is running"
    ps aux | grep -v grep | grep "GigEVirtualCamera.app" | awk '{print "   PID:", $2, "Started:", $9}'
else
    echo "❌ App is not running"
fi

echo ""
echo "2. Camera Discovery:"
log show --last 30s 2>/dev/null | grep -E "GigECameraManager|discoverCameras|Aravis" | grep -v "Not sending frames" | tail -10

echo ""
echo "3. Available Cameras:"
log show --last 30s 2>/dev/null | grep -E "Test Camera|Fake.*Camera|availableCameras|camera discovered" | tail -10

echo ""
echo "4. Connection Status:"
log show --last 30s 2>/dev/null | grep -E "connect.*camera|isConnected|selectedCameraId" | grep -i gige | tail -10

echo ""
echo "5. Sink Connector Status:"
log show --last 30s 2>/dev/null | grep -E "CMIOSinkConnector|sink connector|property listener|waiting for sink" | tail -10

echo ""
echo "6. UserDefaults State:"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null | grep -E "StreamState|Debug_" | head -10