#!/bin/bash

echo "=== Checking Frame Sequence Numbers ==="
echo ""

# Monitor for sequence numbers
log stream --predicate '
    process == "GigECameraExtension" AND 
    (eventMessage CONTAINS "seq:" OR 
     eventMessage CONTAINS "streamingCounter" OR
     eventMessage CONTAINS "Source stream started" OR
     eventMessage CONTAINS "Client count")
' --style compact | while read -r line; do
    if [[ "$line" == *"seq:"* ]]; then
        # Extract sequence number
        seq=$(echo "$line" | grep -o 'seq:[0-9]*' | cut -d: -f2)
        if [[ "$seq" != "0" ]]; then
            echo -e "\033[32m✅ Frame seq:$seq - $line\033[0m"
        else
            echo -e "\033[33m⚠️ Frame seq:0 - $line\033[0m"
        fi
    elif [[ "$line" == *"streamingCounter"* ]] || [[ "$line" == *"Client count"* ]]; then
        echo -e "\033[36m📊 $line\033[0m"
    elif [[ "$line" == *"Source stream started"* ]]; then
        echo -e "\033[35m🎬 $line\033[0m"
    else
        echo "$line"
    fi
done