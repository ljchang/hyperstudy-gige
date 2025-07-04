#!/bin/bash

echo "=== Debugging Frame Flow ==="
echo ""

# Check if processes are running
echo "1. Process Status:"
ps aux | grep -E "GigE" | grep -v grep | awk '{print "   " $11 " (PID: " $2 ")"}'
echo ""

# Check recent logs for connection
echo "2. Recent sink connection attempts:"
log show --last 30s --predicate 'eventMessage CONTAINS "sink" AND process == "GigEVirtualCamera"' --style compact 2>/dev/null | tail -10 || echo "   No recent sink activity"
echo ""

# Check for queue activity
echo "3. Queue activity:"
log show --last 10s --predicate 'eventMessage CONTAINS "Queue" AND process == "GigEVirtualCamera"' --style compact 2>/dev/null | tail -5 || echo "   No recent queue activity"
echo ""

# Check extension activity
echo "4. Extension consumption activity:"
log show --last 10s --predicate 'process == "GigECameraExtension"' --style compact 2>/dev/null | tail -10 || echo "   No recent extension activity"
echo ""

# Monitor live
echo "5. Starting live monitor (connect camera and start streaming)..."
echo ""

log stream --predicate '
    (process == "GigEVirtualCamera" OR process == "GigECameraExtension") AND
    (eventMessage CONTAINS "frame" OR
     eventMessage CONTAINS "Queue" OR
     eventMessage CONTAINS "sink" OR
     eventMessage CONTAINS "buffer" OR
     eventMessage CONTAINS "connect")
' --style syslog 2>/dev/null | while read -r line; do
    if [[ "$line" == *"received REAL frame"* ]] || [[ "$line" == *"Successfully"* ]]; then
        echo -e "\033[32m✅ $line\033[0m"
    elif [[ "$line" == *"Queue is full"* ]] || [[ "$line" == *"Cannot send"* ]]; then
        echo -e "\033[31m❌ $line\033[0m"
    elif [[ "$line" == *"connect"* ]]; then
        echo -e "\033[36m🔗 $line\033[0m"
    else
        echo "$line"
    fi
done