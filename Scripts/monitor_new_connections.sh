#!/bin/bash

echo "=== Monitoring New Client Connections ==="
echo "Start your camera, then connect a new client (QuickTime, etc)"
echo

# Clear console for better visibility
clear

# Monitor for new client connections and frame flow
log stream --predicate '
    subsystem == "com.lukechang.GigEVirtualCamera" OR 
    subsystem == "com.lukechang.GigEVirtualCamera.Extension" OR
    eventMessage CONTAINS "SOURCE STREAM STARTING" OR
    eventMessage CONTAINS "authorizedToStartStream" OR
    eventMessage CONTAINS "startStream" OR
    eventMessage CONTAINS "sendSampleBuffer" OR
    eventMessage CONTAINS "📺" OR
    eventMessage CONTAINS "🎬" OR
    eventMessage CONTAINS "frame" OR
    eventMessage CONTAINS "client"
' --level debug --style compact | while read line; do
    # Highlight important messages
    if [[ $line == *"authorizedToStartStream"* ]]; then
        echo -e "\033[1;32m>>> NEW CLIENT AUTHORIZED: $line\033[0m"
    elif [[ $line == *"SOURCE STREAM STARTING"* ]]; then
        echo -e "\033[1;33m>>> STREAM STARTING: $line\033[0m"
    elif [[ $line == *"sendSampleBuffer"* ]]; then
        echo -e "\033[1;36m>>> FRAME SENT: $line\033[0m"
    elif [[ $line == *"black"* ]] || [[ $line == *"no frame"* ]]; then
        echo -e "\033[1;31m>>> PROBLEM: $line\033[0m"
    else
        echo "$line"
    fi
done