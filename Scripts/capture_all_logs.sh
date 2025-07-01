#!/bin/bash

# Capture logs from the last 5 minutes
echo "Capturing all GigE Virtual Camera logs from the last 5 minutes..."

# Create timestamp for filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/tmp/gige_camera_logs_${TIMESTAMP}.txt"

# Capture logs
log show --predicate 'subsystem contains "com.lukechang.GigEVirtualCamera"' --last 5m --style json > "$LOG_FILE" 2>&1

# Also try with process name
log show --predicate 'process == "GigEVirtualCamera" OR process == "GigECameraExtension"' --last 5m --style json >> "$LOG_FILE" 2>&1

# Convert to readable format
echo "=== GigE Virtual Camera Logs ===" > "/tmp/gige_logs_readable.txt"
echo "Timestamp: $(date)" >> "/tmp/gige_logs_readable.txt"
echo "" >> "/tmp/gige_logs_readable.txt"

# Extract relevant messages
if [ -f "$LOG_FILE" ]; then
    cat "$LOG_FILE" | grep -E '"eventMessage"|"subsystem"|"category"' | sed 's/.*"eventMessage" : "\(.*\)".*/\1/g' | grep -v "^$" >> "/tmp/gige_logs_readable.txt"
fi

# Also check system logs for extension loading
echo -e "\n\n=== System Extension Logs ===" >> "/tmp/gige_logs_readable.txt"
log show --predicate 'process == "sysextd" AND eventMessage contains "lukechang"' --last 5m >> "/tmp/gige_logs_readable.txt" 2>&1

echo "Logs saved to /tmp/gige_logs_readable.txt"
cat "/tmp/gige_logs_readable.txt"