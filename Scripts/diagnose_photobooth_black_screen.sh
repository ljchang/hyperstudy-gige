#!/bin/bash

echo "=== Diagnosing Photo Booth Black Screen Issue ==="
echo ""

# Function to check a specific component
check_component() {
    local component=$1
    local search_term=$2
    echo -n "Checking $component... "
    
    count=$(log show --last 10s 2>/dev/null | grep -i "$search_term" | wc -l)
    if [ $count -gt 0 ]; then
        echo "✅ Active ($count events in last 10s)"
    else
        echo "❌ No activity"
    fi
}

echo "1. Checking Component Activity:"
echo "------------------------------"
check_component "App sending frames" "Queue is full"
check_component "Sink consuming frames" "consumeSampleBuffer received REAL frame"
check_component "DeviceSource forwarding" "Sending frame to source stream"
check_component "Source stream sending" "sendSampleBuffer"
check_component "Photo Booth connection" "authorizedToStartStream"

echo ""
echo "2. Checking Frame Sequence Numbers:"
echo "-----------------------------------"
log show --last 5s 2>/dev/null | grep "seq:" | tail -5 | while read -r line; do
    seq=$(echo "$line" | grep -o 'seq:[0-9]*' | cut -d: -f2)
    echo "Frame sequence: $seq"
done

echo ""
echo "3. Checking Stream States:"
echo "-------------------------"
# Check streamingCounter
counter=$(log show --last 5s 2>/dev/null | grep "clients:" | tail -1 | grep -o 'clients: [0-9]*' | cut -d' ' -f2)
if [ ! -z "$counter" ]; then
    echo "Streaming counter: $counter"
else
    echo "Streaming counter: Unknown"
fi

# Check if sink is active
sink_active=$(log show --last 5s 2>/dev/null | grep "isSinking" | tail -1)
if [ ! -z "$sink_active" ]; then
    echo "Sink status: Active"
else
    echo "Sink status: Unknown"
fi

echo ""
echo "4. Checking for Errors:"
echo "----------------------"
log show --last 10s 2>/dev/null | grep -E "error|Error|ERROR|fail|Fail|FAIL|❌" | grep -i gige | tail -5

echo ""
echo "5. System Extension Status:"
echo "--------------------------"
systemextensionsctl list | grep -A1 "activated enabled" | grep GigE

echo ""
echo "6. Process Status:"
echo "-----------------"
ps aux | grep -i gigecamera | grep -v grep | awk '{print $11}' | while read cmd; do
    echo "✅ Running: $(basename $cmd)"
done

echo ""
echo "7. Photo Booth Camera Status:"
echo "-----------------------------"
system_profiler SPCameraDataType | grep -A5 "GigE Virtual Camera" | head -6

echo ""
echo "Diagnosis complete. Press Ctrl+C to exit."