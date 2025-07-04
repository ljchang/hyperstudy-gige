#!/bin/bash

echo "=== Checking Source Stream Connection ==="
echo ""

# Look for source stream activity
log show --last 60s 2>/dev/null | grep -E "Source stream|streamingCounter|Client count|startStreaming|🎬" | grep -i gige | tail -30 | while read -r line; do
    if [[ "$line" == *"streamingCounter"* ]] || [[ "$line" == *"Client count"* ]]; then
        echo -e "\033[36m📊 CLIENT: $line\033[0m"
    elif [[ "$line" == *"Source stream started"* ]] || [[ "$line" == *"🎬"* ]]; then
        echo -e "\033[35m🎬 SOURCE: $line\033[0m"
    elif [[ "$line" == *"startStreaming"* ]]; then
        echo -e "\033[32m✅ START: $line\033[0m"
    else
        echo "$line"
    fi
done

echo ""
echo "Checking if frames are being sent to source stream..."
log show --last 10s 2>/dev/null | grep -E "Source sending frame|sendSampleBuffer|🚀" | tail -10