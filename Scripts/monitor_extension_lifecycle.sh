#!/bin/bash

echo "=== Monitoring Extension Lifecycle ==="
echo "Open Photo Booth and select GigE Virtual Camera..."
echo ""

# Function to check if extension is running
check_extension() {
    if pgrep -f "GigECameraExtension" > /dev/null; then
        echo "[$(date +%H:%M:%S)] ✅ Extension is running (PID: $(pgrep -f GigECameraExtension))"
        return 0
    else
        echo "[$(date +%H:%M:%S)] ❌ Extension is NOT running"
        return 1
    fi
}

# Monitor extension lifecycle
echo "Starting monitoring..."
LAST_STATE=""
while true; do
    if check_extension; then
        if [ "$LAST_STATE" != "running" ]; then
            echo "[$(date +%H:%M:%S)] 🟢 Extension STARTED"
            LAST_STATE="running"
            
            # Check for any immediate errors
            sleep 1
            log show --predicate 'process == "GigECameraExtension"' --last 5s --info 2>&1 | grep -E "error|Error|fail|Fatal" | head -5
        fi
    else
        if [ "$LAST_STATE" == "running" ]; then
            echo "[$(date +%H:%M:%S)] 🔴 Extension STOPPED/CRASHED"
            
            # Check crash logs
            echo "Checking for crash reason..."
            log show --predicate 'process == "GigECameraExtension" OR process == "kernel"' --last 10s --info 2>&1 | grep -E "exit|terminated|crash|EXC_" | head -10
            
            # Check system logs for termination reason
            log show --predicate 'eventMessage CONTAINS "GigECameraExtension"' --last 10s --info 2>&1 | grep -E "terminated|killed|exit" | head -5
        fi
        LAST_STATE="stopped"
    fi
    sleep 0.5
done