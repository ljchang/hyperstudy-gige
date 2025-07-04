#!/bin/bash

echo "=== Monitoring Enhanced Frame Flow Debugging ==="
echo "This script monitors the detailed frame flow logs added for debugging"
echo ""
echo "Legend:"
echo "  🔵 - Sink stream operations"
echo "  ✅ - Successful frame receipt/forward"
echo "  📤 - Frame forwarding"
echo "  🚀 - Source stream sending"
echo "  ⚠️  - Warnings (dropped frames, missing callbacks)"
echo "  ❌ - Errors"
echo "  🎬 - Client connections"
echo "  🎯 - Bridge setup"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo "=============================================="
echo ""

# Monitor logs with the new debug markers
log stream --level debug --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" && (
    eventMessage CONTAINS "🔵" OR 
    eventMessage CONTAINS "✅" OR 
    eventMessage CONTAINS "📤" OR 
    eventMessage CONTAINS "🚀" OR 
    eventMessage CONTAINS "⚠️" OR 
    eventMessage CONTAINS "❌" OR 
    eventMessage CONTAINS "🎬" OR 
    eventMessage CONTAINS "🎯" OR
    eventMessage CONTAINS "Re-subscribing" OR
    eventMessage CONTAINS "Sink received frame" OR
    eventMessage CONTAINS "Forwarding frame" OR
    eventMessage CONTAINS "Source sending frame" OR
    eventMessage CONTAINS "Client count" OR
    eventMessage CONTAINS "bridge"
)' --style compact | while read -r line; do
    # Color code the output based on emoji markers
    if [[ "$line" == *"❌"* ]]; then
        echo -e "\033[31m$line\033[0m"  # Red for errors
    elif [[ "$line" == *"⚠️"* ]]; then
        echo -e "\033[33m$line\033[0m"  # Yellow for warnings
    elif [[ "$line" == *"✅"* ]] || [[ "$line" == *"🚀"* ]] || [[ "$line" == *"📤"* ]]; then
        echo -e "\033[32m$line\033[0m"  # Green for success
    elif [[ "$line" == *"🔵"* ]] || [[ "$line" == *"🎯"* ]]; then
        echo -e "\033[36m$line\033[0m"  # Cyan for sink/bridge operations
    elif [[ "$line" == *"🎬"* ]]; then
        echo -e "\033[35m$line\033[0m"  # Magenta for client operations
    else
        echo "$line"
    fi
done