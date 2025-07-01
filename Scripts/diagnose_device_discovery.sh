#!/bin/bash

echo "=== Diagnosing Device Discovery Issue ==="
echo ""

# 1. Check if extension is installed
echo "1. Checking system extension status..."
systemextensionsctl list | grep -i gige
echo ""

# 2. Check if extension process is running
echo "2. Checking if extension process is running..."
ps aux | grep -i "GigEVirtualCameraExtension" | grep -v grep
echo ""

# 3. Force extension restart
echo "3. Forcing extension restart..."
pid=$(pgrep GigEVirtualCameraExtension)
if [ ! -z "$pid" ]; then
    echo "Killing extension process: $pid"
    sudo kill -9 $pid
    sleep 2
fi

# 4. Trigger extension load and capture logs
echo ""
echo "4. Triggering extension load..."
# Start log capture in background
log stream --predicate 'subsystem contains "com.lukechang.GigEVirtualCamera"' --style compact > /tmp/gige_discovery_logs.txt 2>&1 &
LOG_PID=$!

# Trigger camera enumeration (this should load the extension)
system_profiler SPCameraDataType > /dev/null 2>&1

# Give it time to load
sleep 3

# Kill log capture
kill $LOG_PID 2>/dev/null

# 5. Check if virtual camera appears in system
echo ""
echo "5. Checking system camera list..."
system_profiler SPCameraDataType | grep -A5 -B5 "GigE"

# 6. Check CMIO devices via Apple's tool
echo ""
echo "6. Checking CMIO devices..."
if command -v cmio &> /dev/null; then
    cmio list devices
else
    echo "cmio tool not found"
fi

# 7. Show relevant logs
echo ""
echo "7. Extension initialization logs:"
grep -E "(Extension Starting|Creating provider|Creating device|Added device|device created with ID)" /tmp/gige_discovery_logs.txt | tail -20

echo ""
echo "8. Device discovery logs:"
grep -E "(device discovery|Found|Searching|Device|Virtual camera)" /tmp/gige_discovery_logs.txt | tail -20

# 8. Check for errors
echo ""
echo "9. Any errors:"
grep -iE "(error|fail|cannot)" /tmp/gige_discovery_logs.txt | tail -10

# Cleanup
rm -f /tmp/gige_discovery_logs.txt

echo ""
echo "=== Diagnosis Complete ==="