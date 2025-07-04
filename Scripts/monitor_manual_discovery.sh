#!/bin/bash

echo "=== Monitoring Manual Discovery Logs ==="
echo ""

# Monitor for manual discovery attempts
log stream --predicate '
    eventMessage CONTAINS[c] "manual discovery" OR
    eventMessage CONTAINS[c] "CMIOSinkConnector" OR
    eventMessage CONTAINS[c] "Found virtual camera" OR
    eventMessage CONTAINS[c] "Found sink stream" OR
    eventMessage CONTAINS[c] "attempting connection" OR
    eventMessage CONTAINS[c] "property listener" OR
    eventMessage CONTAINS[c] "device discovered" OR
    eventMessage CONTAINS[c] "target device UID" OR
    eventMessage CONTAINS[c] "Cannot send frame"
' --style compact | while read -r line; do
    # Highlight important messages
    if [[ "$line" == *"Found virtual camera"* ]] || [[ "$line" == *"Found sink stream"* ]]; then
        echo -e "\033[32m✅ $line\033[0m"
    elif [[ "$line" == *"Failed"* ]] || [[ "$line" == *"Error"* ]] || [[ "$line" == *"Cannot send"* ]]; then
        echo -e "\033[31m❌ $line\033[0m"
    elif [[ "$line" == *"manual discovery"* ]]; then
        echo -e "\033[33m🔍 $line\033[0m"
    else
        echo "$line"
    fi
done