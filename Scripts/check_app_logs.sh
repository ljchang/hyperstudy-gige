#!/bin/bash

echo "=== Checking GigEVirtualCamera App Logs ==="
echo ""

# Get the PID of the app
APP_PID=$(ps aux | grep -i "GigEVirtualCamera.app" | grep -v grep | awk '{print $2}')
EXT_PID=$(ps aux | grep -i "GigECameraExtension" | grep -v grep | awk '{print $2}')

echo "App PID: $APP_PID"
echo "Extension PID: $EXT_PID"
echo ""

# Check logs for the app process
if [ ! -z "$APP_PID" ]; then
    echo "=== App Process Logs (PID: $APP_PID) ==="
    log show --process $APP_PID --last 1m --info 2>/dev/null | tail -30
    echo ""
fi

# Check logs for the extension process
if [ ! -z "$EXT_PID" ]; then
    echo "=== Extension Process Logs (PID: $EXT_PID) ==="
    log show --process $EXT_PID --last 1m --info 2>/dev/null | tail -30
    echo ""
fi

# Check for any GigE related logs
echo "=== All GigE Related Logs ==="
log show --last 1m 2>/dev/null | grep -E "(GigE|gige|Virtual Camera|IOSurface ID:|Frame #|📤|📥)" | tail -30