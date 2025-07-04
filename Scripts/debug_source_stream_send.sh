#!/bin/bash

echo "=== Debugging Source Stream Send Method ==="
echo ""

# Monitor all relevant logs
log stream --predicate '
    process == "GigECameraExtension" AND 
    (eventMessage CONTAINS "sendSampleBuffer" OR
     eventMessage CONTAINS "Forwarding frame" OR
     eventMessage CONTAINS "DeviceSource received frame" OR
     eventMessage CONTAINS "Sending frame to source" OR
     eventMessage CONTAINS "Frame sent to CMIO" OR
     eventMessage CONTAINS "Source sending frame" OR
     eventMessage CONTAINS "📺" OR
     eventMessage CONTAINS "🚀" OR
     eventMessage CONTAINS "📤" OR
     eventMessage CONTAINS "🔄")
' --style compact | while read -r line; do
    if [[ "$line" == *"sendSampleBuffer"* ]]; then
        echo -e "\033[32m✅ SEND: $line\033[0m"
    elif [[ "$line" == *"Forwarding frame"* ]] || [[ "$line" == *"📤"* ]]; then
        echo -e "\033[35m📤 FORWARD: $line\033[0m"
    elif [[ "$line" == *"DeviceSource received"* ]] || [[ "$line" == *"🔄"* ]]; then
        echo -e "\033[36m🔄 RECEIVED: $line\033[0m"
    elif [[ "$line" == *"Sending frame to source"* ]] || [[ "$line" == *"🚀"* ]]; then
        echo -e "\033[33m🚀 SENDING: $line\033[0m"
    elif [[ "$line" == *"Frame sent"* ]] || [[ "$line" == *"📺"* ]]; then
        echo -e "\033[32m📺 SENT: $line\033[0m"
    else
        echo "$line"
    fi
done