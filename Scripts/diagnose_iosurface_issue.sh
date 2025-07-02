#!/bin/bash

echo "Diagnosing IOSurface Frame Flow Issue"
echo "===================================="

# Check if app is running
APP_PID=$(pgrep GigEVirtualCamera || echo "Not running")
echo "App PID: $APP_PID"

# Check if extension is running  
EXT_PID=$(pgrep GigECameraExtension || echo "Not running")
echo "Extension PID: $EXT_PID"

# Check shared defaults
echo -e "\nChecking shared UserDefaults..."
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || echo "No shared defaults found"

# Monitor logs
echo -e "\nMonitoring frame flow logs..."
echo "Looking for:"
echo "- IOSurfaceFrameWriter: Frame writes"
echo "- FrameCache: Frame reads"
echo "- StreamSource: Frame sends"
echo -e "\nPress Ctrl+C to stop...\n"

log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension"' | grep -E "(IOSurfaceFrameWriter|FrameCache|StreamSource|Frame #|IOSurface:)"