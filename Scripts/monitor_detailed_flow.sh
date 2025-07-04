#!/bin/bash

echo "=== Monitoring Detailed Frame Flow ==="
echo "Please restart the extension and open Photo Booth"
echo ""

# Kill any existing monitors
killall -9 log 2>/dev/null

# Start monitoring
log stream --predicate '
    process == "GigECameraExtension" OR 
    process == "GigEVirtualCamera" OR
    eventMessage CONTAINS "🔵" OR 
    eventMessage CONTAINS "🟢" OR 
    eventMessage CONTAINS "🎬" OR 
    eventMessage CONTAINS "❌" OR
    eventMessage CONTAINS "✅" OR
    eventMessage CONTAINS "📤" OR
    eventMessage CONTAINS "⚠️" OR
    eventMessage CONTAINS "consumeSampleBuffer" OR
    eventMessage CONTAINS "SINK" OR
    eventMessage CONTAINS "SOURCE" OR
    eventMessage CONTAINS "seq:" OR
    eventMessage CONTAINS "hasMore:" OR
    eventMessage CONTAINS "sampleBuffer" OR
    eventMessage CONTAINS "frame"
' --style compact | while read -r line; do
    # Color code based on content
    if [[ "$line" == *"❌"* ]]; then
        echo -e "\033[31m$line\033[0m"  # Red for errors
    elif [[ "$line" == *"🟢"* ]]; then
        echo -e "\033[32m$line\033[0m"  # Green for sink start
    elif [[ "$line" == *"🎬"* ]]; then
        echo -e "\033[35m$line\033[0m"  # Magenta for source start
    elif [[ "$line" == *"🔵"* ]]; then
        echo -e "\033[36m$line\033[0m"  # Cyan for subscription
    elif [[ "$line" == *"✅"* ]]; then
        echo -e "\033[32m$line\033[0m"  # Green for success
    elif [[ "$line" == *"📤"* ]]; then
        echo -e "\033[34m$line\033[0m"  # Blue for sending
    elif [[ "$line" == *"⚠️"* ]]; then
        echo -e "\033[33m$line\033[0m"  # Yellow for warnings
    else
        echo "$line"
    fi
done