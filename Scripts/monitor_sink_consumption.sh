#!/bin/bash

echo "=== Monitoring Sink Stream Frame Consumption ==="
echo "Watching for sink stream activity..."
echo ""

# Monitor extension logs
log stream --level debug | grep -E "GigECamera|Sink|sink|🔵|✅|📤|🚀|⚠️|❌|🎬|🎯|Re-subscribing|Forwarding|Client count|bridge" | while read -r line; do
    # Only show lines from our extension
    if [[ "$line" == *"com.lukechang.GigEVirtualCamera"* ]]; then
        # Color code based on content
        if [[ "$line" == *"❌"* ]] || [[ "$line" == *"error"* ]]; then
            echo -e "\033[31m$line\033[0m"  # Red
        elif [[ "$line" == *"⚠️"* ]] || [[ "$line" == *"warning"* ]]; then
            echo -e "\033[33m$line\033[0m"  # Yellow
        elif [[ "$line" == *"✅"* ]] || [[ "$line" == *"🚀"* ]] || [[ "$line" == *"📤"* ]]; then
            echo -e "\033[32m$line\033[0m"  # Green
        elif [[ "$line" == *"🔵"* ]] || [[ "$line" == *"🎯"* ]]; then
            echo -e "\033[36m$line\033[0m"  # Cyan
        elif [[ "$line" == *"🎬"* ]]; then
            echo -e "\033[35m$line\033[0m"  # Magenta
        else
            echo "$line"
        fi
    fi
done