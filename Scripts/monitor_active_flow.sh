#!/bin/bash

echo "=== Monitoring Active Frame Flow ==="
echo "Photo Booth should be open with GigE Virtual Camera selected"
echo ""

log stream --predicate '
    (process == "GigEVirtualCamera" OR process == "GigECameraExtension") AND
    (eventMessage CONTAINS "Queue" OR 
     eventMessage CONTAINS "frame" OR
     eventMessage CONTAINS "✅" OR
     eventMessage CONTAINS "📤" OR
     eventMessage CONTAINS "consumeSampleBuffer")
' --style compact | while read -r line; do
    if [[ "$line" == *"Queue is full"* ]]; then
        echo -e "\033[31m❌ QUEUE FULL: $line\033[0m"
    elif [[ "$line" == *"received REAL frame"* ]] || [[ "$line" == *"✅"* ]]; then
        echo -e "\033[32m✅ SUCCESS: $line\033[0m"
    elif [[ "$line" == *"Forwarding"* ]] || [[ "$line" == *"📤"* ]]; then
        echo -e "\033[35m📤 FORWARD: $line\033[0m"
    elif [[ "$line" == *"Sent frame"* ]]; then
        echo -e "\033[36m📊 SENT: $line\033[0m"
    elif [[ "$line" == *"consumeSampleBuffer"* ]]; then
        echo -e "\033[33m🔵 CONSUME: $line\033[0m"
    elif [[ "$line" == *"Received frame"* ]] && [[ "$line" == *"AravisBridge"* ]]; then
        # Skip Aravis frame logs to reduce noise
        continue
    else
        echo "$line"
    fi
done