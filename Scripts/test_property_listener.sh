#!/bin/bash
#
# test_property_listener.sh
# Test if property listener is initializing and working
#

echo "Testing Property Listener..."
echo ""

# Kill existing app
echo "1. Stopping existing app..."
killall GigEVirtualCamera 2>/dev/null || true
sleep 1

# Clear log
echo "2. Clearing log..."
sudo log erase --all 2>/dev/null || true

# Start app
echo "3. Starting app..."
open /Applications/GigEVirtualCamera.app

# Wait for startup
echo "4. Waiting for startup..."
sleep 3

# Check for initialization
echo "5. Checking logs..."
echo ""

# Check for property listener initialization
echo "=== Property Listener Initialization ==="
log show --last 30s --predicate 'eventMessage CONTAINS "CMIOPropertyListener"' 2>/dev/null || echo "No property listener logs found"

echo ""
echo "=== CMIOSinkConnector Initialization ==="
log show --last 30s --predicate 'eventMessage CONTAINS "CMIOSinkConnector"' 2>/dev/null || echo "No sink connector logs found"

echo ""
echo "=== All GigE Virtual Camera Logs ==="
log show --last 30s --predicate 'eventMessage CONTAINS "GigEVirtualCamera"' 2>/dev/null | head -50 || echo "No logs found"

echo ""
echo "=== Check if extension starts when Photo Booth connects ==="
echo "Please select 'GigE Virtual Camera' in Photo Booth..."
sleep 5

# Check for extension
if pgrep -f "GigEVirtualCameraExtension" > /dev/null; then
    echo "✅ Extension is now running!"
else
    echo "❌ Extension is not running"
fi

# Check recent logs again
echo ""
echo "=== Recent activity logs ==="
log show --last 10s --predicate 'eventMessage CONTAINS[c] "gige" OR eventMessage CONTAINS "virtual camera"' 2>/dev/null | tail -20