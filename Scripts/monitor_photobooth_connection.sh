#!/bin/bash

echo "=== Monitoring Photo Booth Connection ==="
echo "Please select 'GigE Virtual Camera' in Photo Booth"
echo ""

log stream --predicate '
    (eventMessage CONTAINS "authorizedToStartStream" OR
     eventMessage CONTAINS "SOURCE STREAM STARTING" OR
     eventMessage CONTAINS "streamingCounter" OR
     eventMessage CONTAINS "startStreaming" OR
     eventMessage CONTAINS "Client count" OR
     eventMessage CONTAINS "🎬") AND
    process == "GigECameraExtension"
' --style compact | while read -r line; do
    if [[ "$line" == *"authorizedToStartStream"* ]]; then
        echo -e "\033[32m✅ AUTHORIZED: $line\033[0m"
    elif [[ "$line" == *"SOURCE STREAM STARTING"* ]] || [[ "$line" == *"🎬"* ]]; then
        echo -e "\033[35m🎬 STARTED: $line\033[0m"
    elif [[ "$line" == *"streamingCounter"* ]] || [[ "$line" == *"Client count"* ]]; then
        echo -e "\033[36m📊 CLIENTS: $line\033[0m"
    else
        echo "$line"
    fi
done