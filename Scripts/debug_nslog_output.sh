#!/bin/bash

echo "=== Debugging NSLog Output ==="
echo "Looking for our debug markers..."
echo ""

# Get extension PID
EXT_PID=$(ps aux | grep GigECameraExtension | grep -v grep | awk '{print $2}')
if [ -z "$EXT_PID" ]; then
    echo "❌ Extension is NOT running!"
    exit 1
fi

echo "✅ Extension is running (PID: $EXT_PID)"
echo ""

# Monitor for our specific NSLog patterns
echo "Monitoring for debug output:"
echo "  🟢🟢🟢 - Sink stream starting"
echo "  🎬🎬🎬 - Source stream starting"
echo "  🔵🔵🔵 - Sink subscribing"
echo ""

# Monitor system log for our patterns
log stream --process $EXT_PID --level debug | grep -E "🟢🟢🟢|🎬🎬🎬|🔵🔵🔵|SINK|SOURCE|SUBSCRIBING" --line-buffered | while read -r line; do
    # Color code the output
    if [[ "$line" == *"🟢🟢🟢"* ]]; then
        echo -e "\033[32m✅ SINK: $line\033[0m"
    elif [[ "$line" == *"🎬🎬🎬"* ]]; then
        echo -e "\033[35m🎬 SOURCE: $line\033[0m"
    elif [[ "$line" == *"🔵🔵🔵"* ]]; then
        echo -e "\033[36m🔵 SUBSCRIBE: $line\033[0m"
    else
        echo "$line"
    fi
done