#!/bin/bash

echo "=== Testing Virtual Camera Registration ==="
echo ""

# Test 1: Check if extension is running
echo "1. Extension Process Status:"
ps aux | grep -i GigECameraExtension | grep -v grep
echo ""

# Test 2: Check system camera list
echo "2. System Camera List:"
system_profiler SPCameraDataType 2>/dev/null | grep -A5 -B5 "GigE" || echo "GigE Virtual Camera not found in system cameras"
echo ""

# Test 3: Check CMIO logs for our device
echo "3. Recent CMIO Device Registration Logs:"
log show --predicate 'process == "GigECameraExtension"' --last 30s --info | grep -E "(device|Device|stream|Stream|sink|source)" | tail -20
echo ""

# Test 4: Check for extension initialization
echo "4. Extension Initialization Logs:"
log show --predicate 'process == "GigECameraExtension"' --last 1m --info | grep -E "(Starting|Creating|initialization|Successfully added device)" | tail -10
echo ""

# Test 5: Check CoreMediaIO framework logs
echo "5. CoreMediaIO Framework Activity:"
log show --predicate 'subsystem == "com.apple.cmio" AND eventMessage CONTAINS[c] "gige"' --last 2m --info | tail -20
echo ""

echo "=== End of diagnostics ==="