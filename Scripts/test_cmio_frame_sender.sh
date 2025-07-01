#!/bin/bash

echo "=== Test CMIO Frame Sender Connection ==="
echo

# 1. List all CMIO devices to confirm virtual camera exists
echo "1. Current CMIO devices:"
swift /Users/lukechang/Github/hyperstudy-gige/Scripts/list_cmio_devices.swift 2>&1 | grep -E "Device ID:|Name:" | grep -B1 "GigE"

echo
echo "2. Check if extension is running:"
ps aux | grep -i "GigECameraExtension" | grep -v grep | awk '{print "PID:", $2, "Started:", $9}'

echo
echo "3. Recent connection attempts:"
log show --predicate 'process == "GigEVirtualCamera"' --last 30s | grep -E "Virtual camera|CMIO|connect|device" | tail -10

echo
echo "4. The issue might be:"
echo "   - CMIOFrameSender is running too early"
echo "   - Need to increase retry delay"
echo "   - Device enumeration timing issue"
echo
echo "5. Try this workaround:"
echo "   - In the app, disconnect the camera (select None)"
echo "   - Wait 2 seconds"
echo "   - Reconnect the camera"
echo "   This should trigger setupFrameSender() again"