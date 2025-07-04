#!/bin/bash

echo "=== Testing Complete Frame Flow ==="
echo ""

# 1. Check if extension is running
echo "1. Extension status:"
ps aux | grep -E "GigECameraExtension" | grep -v grep
echo ""

# 2. Check virtual camera in system
echo "2. Virtual camera in system:"
system_profiler SPCameraDataType | grep -A5 "GigE"
echo ""

# 3. Monitor frame flow logs
echo "3. Starting log monitor (connect camera and start streaming in the app)..."
echo ""

log stream --predicate '
    (eventMessage CONTAINS "Sent frame" OR
     eventMessage CONTAINS "Cannot send frame" OR
     eventMessage CONTAINS "First frame sent" OR
     eventMessage CONTAINS "consumeSampleBuffer callback" OR
     eventMessage CONTAINS "Sink received frame" OR
     eventMessage CONTAINS "Forwarding frame" OR
     eventMessage CONTAINS "Source sending frame" OR
     eventMessage CONTAINS "Queue is full" OR
     eventMessage CONTAINS "connected to sink" OR
     eventMessage CONTAINS "sink stream") AND
    (process == "GigEVirtualCamera" OR
     process == "GigECameraExtension")
' --style syslog | while read -r line; do
    if [[ "$line" == *"Sent frame"* ]] || [[ "$line" == *"First frame"* ]]; then
        echo -e "\033[32m✅ $line\033[0m"
    elif [[ "$line" == *"Cannot send"* ]] || [[ "$line" == *"Queue is full"* ]]; then
        echo -e "\033[31m❌ $line\033[0m"
    elif [[ "$line" == *"consumeSampleBuffer"* ]] || [[ "$line" == *"Sink received"* ]]; then
        echo -e "\033[36m🔵 $line\033[0m"
    elif [[ "$line" == *"Forwarding"* ]] || [[ "$line" == *"Source sending"* ]]; then
        echo -e "\033[35m🚀 $line\033[0m"
    else
        echo "$line"
    fi
done