#!/bin/bash

echo "=== Comprehensive GigE Virtual Camera Log Analysis ==="
echo "Timestamp: $(date)"
echo ""

# Create a temporary file for logs
LOGFILE="/tmp/gige_camera_full_logs.txt"

echo "1. Collecting logs from the last 2 minutes..."
log show --predicate 'subsystem contains "com.lukechang.GigEVirtualCamera"' --last 2m --style json > "$LOGFILE" 2>&1

echo ""
echo "2. Analyzing app logs..."
echo "=== APP LOGS ==="
cat "$LOGFILE" | grep -E '"eventMessage"' | grep -E "(CameraManager|FrameSender|CMIOFrameSender)" | sed 's/.*"eventMessage" : "\(.*\)".*/\1/' | tail -30

echo ""
echo "3. Analyzing extension logs..."
echo "=== EXTENSION LOGS ==="
cat "$LOGFILE" | grep -E '"eventMessage"' | grep -E "(Extension|DeviceSource|StreamSource|SinkStreamSource)" | sed 's/.*"eventMessage" : "\(.*\)".*/\1/' | tail -30

echo ""
echo "4. Looking for sink/stream activity..."
echo "=== SINK/STREAM ACTIVITY ==="
cat "$LOGFILE" | grep -E '"eventMessage"' | grep -iE "(sink|stream|queue|frame|connect)" | sed 's/.*"eventMessage" : "\(.*\)".*/\1/' | tail -20

echo ""
echo "5. Checking for errors..."
echo "=== ERRORS ==="
cat "$LOGFILE" | grep -E '"eventMessage"' | grep -iE "(error|fail|cannot|unable)" | sed 's/.*"eventMessage" : "\(.*\)".*/\1/' | tail -20

echo ""
echo "6. Process status..."
echo "=== PROCESSES ==="
ps aux | grep -E "(GigE|Camera)" | grep -v grep

echo ""
echo "7. System extension status..."
echo "=== SYSTEM EXTENSIONS ==="
systemextensionsctl list | grep -i gige

echo ""
echo "8. Checking for device discovery..."
echo "=== DEVICE DISCOVERY ==="
cat "$LOGFILE" | grep -E '"eventMessage"' | grep -iE "(device|found|search|discover)" | sed 's/.*"eventMessage" : "\(.*\)".*/\1/' | tail -20

# Also check system logs for CMIO activity
echo ""
echo "9. CMIO system activity..."
echo "=== CMIO SYSTEM LOGS ==="
log show --predicate 'process == "cmiodalassistants" OR process == "VDCAssistant"' --last 1m 2>/dev/null | grep -i "gige" | tail -10

# Clean up
rm -f "$LOGFILE"