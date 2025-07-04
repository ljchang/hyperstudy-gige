#!/bin/bash

echo "=== Testing Complete Virtual Camera Flow ==="
echo ""

# Function to wait for a condition
wait_for() {
    local message=$1
    local check_command=$2
    local timeout=${3:-30}
    
    echo -n "$message"
    
    for i in $(seq 1 $timeout); do
        if eval "$check_command" >/dev/null 2>&1; then
            echo " ✅"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    echo " ❌ (timeout)"
    return 1
}

# 1. Ensure app is running
echo "1. Starting app..."
if ! ps aux | grep -v grep | grep -q "GigEVirtualCamera.app"; then
    open /Applications/GigEVirtualCamera.app
    wait_for "Waiting for app to start" "ps aux | grep -v grep | grep -q 'GigEVirtualCamera.app'"
else
    echo "   App already running ✅"
fi

# 2. Check extension
echo ""
echo "2. Checking extension..."
if systemextensionsctl list | grep -q "activated enabled.*GigE"; then
    echo "   Extension is active ✅"
else
    echo "   Extension not active ❌"
fi

# 3. Monitor camera discovery
echo ""
echo "3. Monitoring camera discovery..."
echo "   Checking for cameras in the last 10 seconds..."
log show --last 10s 2>/dev/null | grep -E "Test Camera|discoverCameras|availableCameras" | tail -5

# 4. Check sink connection
echo ""
echo "4. Checking sink connection..."
log show --last 10s 2>/dev/null | grep -E "isFrameSenderConnected|sink.*connect|CMIOSinkConnector" | tail -5

# 5. Check frame flow
echo ""
echo "5. Checking frame flow..."
./Scripts/diagnose_photobooth_black_screen.sh | grep -A1 "Checking Component Activity"

# 6. Monitor Photo Booth
echo ""
echo "6. Monitoring Photo Booth connection..."
echo "   Please open Photo Booth and select 'GigE Virtual Camera'"
echo "   Monitoring for connection attempts..."

# Start monitoring in background
log stream --predicate 'process == "GigECameraExtension" AND eventMessage CONTAINS "authorizedToStartStream"' --style compact &
MONITOR_PID=$!

# Wait for user input
echo ""
echo "Press Enter after selecting the camera in Photo Booth..."
read

# Kill monitor
kill $MONITOR_PID 2>/dev/null

# Final check
echo ""
echo "7. Final status check..."
./Scripts/diagnose_photobooth_black_screen.sh