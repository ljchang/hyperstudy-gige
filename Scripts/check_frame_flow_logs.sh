#!/bin/bash

echo "=== Checking GigE Virtual Camera Frame Flow Logs ==="
echo "Looking for IOSurface IDs and frame flow..."
echo ""

# Check app logs
echo "=== App Logs (Frame Generation) ==="
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' --last 2m --info --debug | grep -E "(IOSurface|frame|Frame|📤|📥|✅|⚠️|Calling delegate|Sending frame|Fake camera)" | tail -30

echo ""
echo "=== Extension Logs (Frame Reception) ==="
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 2m --info --debug | grep -E "(IOSurface|frame|Frame|📤|📥|✅|⚠️|Received|Forwarding|consumeSampleBuffer|enqueueSampleBuffer)" | tail -30

echo ""
echo "=== CMIOFrameSender Connection Status ==="
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "FrameSender"' --last 2m --info | grep -E "(connect|Connect|sink|queue|device|found|Found|Successfully)" | tail -20

echo ""
echo "=== Check Extension Sink Stream ==="
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category == "SinkStreamSource"' --last 2m --info --debug | tail -20

echo ""
echo "=== Check for Stream Creation ==="
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 2m --info | grep -E "(stream|Stream|device|Device|created|Creating)" | tail -20

echo ""
echo "=== Check Virtual Camera Device Discovery ==="
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "FrameSender"' --last 2m --info | grep -E "(device|Device|GigE Virtual Camera|found|Found)" | tail -20