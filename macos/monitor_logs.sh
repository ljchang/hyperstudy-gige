#!/bin/bash

echo "Monitoring GigEVirtualCamera logs..."
echo "Press Ctrl+C to stop"
echo "=================================="

# Monitor logs using log stream
log stream --predicate 'eventMessage contains "AravisBridge" or eventMessage contains "GigECameraManager" or eventMessage contains "PreviewFrameHandler"' --style syslog