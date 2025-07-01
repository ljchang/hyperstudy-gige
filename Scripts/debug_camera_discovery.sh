#!/bin/bash

echo "=== Debugging Camera Discovery ==="
echo

# 1. Check if Aravis can see cameras on the network
echo "1. Testing Aravis camera discovery:"
if command -v arv-camera-test-0.8 &> /dev/null; then
    arv-camera-test-0.8 2>&1 | head -20 || echo "No cameras found by Aravis"
else
    echo "arv-camera-test-0.8 not found. Install with: brew install aravis"
fi

echo
echo "2. Check if app is running:"
ps aux | grep -i "gigev" | grep -v grep

echo
echo "3. Recent app logs:"
log show --predicate 'process == "GigEVirtualCamera"' --last 5m | grep -i "camera\|discover\|manager\|gige" | tail -20

echo
echo "4. Check network interfaces:"
ifconfig | grep -A 1 "inet " | grep -v "127.0.0.1"

echo
echo "5. Common issues:"
echo "   - GigE cameras must be on same network subnet"
echo "   - Firewall may block camera discovery (UDP port 3956)"
echo "   - Camera may need power cycle"
echo "   - Check camera's IP configuration"

echo
echo "6. To manually trigger camera discovery in the app:"
echo "   - Quit and restart the app"
echo "   - Or check if there's a 'Refresh' button in the UI"