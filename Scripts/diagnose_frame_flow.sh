#!/bin/bash

echo "=== GigE Virtual Camera Frame Flow Diagnostics ==="
echo "Timestamp: $(date)"
echo ""

# Check if extension is running
echo "1. Checking if extension is running..."
ps aux | grep -i "GigECameraExtension" | grep -v grep
echo ""

# Check if app is running
echo "2. Checking if app is running..."
ps aux | grep -i "GigEVirtualCamera.app" | grep -v grep
echo ""

# Check system extension status
echo "3. System extension status:"
systemextensionsctl list | grep -i "gige"
echo ""

# Check recent logs
echo "4. Recent logs (last 30 seconds):"
log show --predicate 'subsystem contains "com.lukechang.GigEVirtualCamera"' --last 30s --style compact | grep -E "(sink|stream|frame|Frame|connect|Connect|device|Device)" | tail -50

echo ""
echo "5. Checking for CMIO devices:"
system_profiler SPCameraDataType | grep -A5 "GigE"