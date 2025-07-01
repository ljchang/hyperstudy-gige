#!/bin/bash

echo "Monitoring GigE Virtual Camera logs..."
echo "Press Ctrl+C to stop"
echo ""

# Stream logs from both app and extension
log stream --predicate 'subsystem contains "com.lukechang.GigEVirtualCamera"' --style compact | grep -E "(XPC|frame|Frame|surface|IOSurface|error|Error|start|Started|Received|Sent)"