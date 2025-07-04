#!/bin/bash

echo "=== Monitoring Frame Consumption ==="
echo ""
echo "Please:"
echo "1. Connect to a camera in the app"
echo "2. Start streaming"
echo "3. Open Photo Booth and select 'GigE Virtual Camera'"
echo ""

# Monitor for frame consumption
log stream --predicate '
    eventMessage CONTAINS[c] "consumeSampleBuffer callback" OR
    eventMessage CONTAINS[c] "Sink received frame" OR
    eventMessage CONTAINS[c] "Queue is full" OR
    eventMessage CONTAINS[c] "Forwarding frame" OR
    eventMessage CONTAINS[c] "No consumer callback" OR
    eventMessage CONTAINS[c] "🔵" OR
    eventMessage CONTAINS[c] "✅" OR
    eventMessage CONTAINS[c] "⚠️" OR
    eventMessage CONTAINS[c] "❌"
' --style compact | while read -r line; do
    # Color code the output
    if [[ "$line" == *"✅"* ]] || [[ "$line" == *"Sink received frame"* ]]; then
        echo -e "\033[32m$line\033[0m"  # Green for success
    elif [[ "$line" == *"❌"* ]] || [[ "$line" == *"Queue is full"* ]]; then
        echo -e "\033[31m$line\033[0m"  # Red for errors
    elif [[ "$line" == *"🔵"* ]] || [[ "$line" == *"consumeSampleBuffer"* ]]; then
        echo -e "\033[36m$line\033[0m"  # Cyan for callbacks
    elif [[ "$line" == *"⚠️"* ]] || [[ "$line" == *"No consumer"* ]]; then
        echo -e "\033[33m$line\033[0m"  # Yellow for warnings
    else
        echo "$line"
    fi
done