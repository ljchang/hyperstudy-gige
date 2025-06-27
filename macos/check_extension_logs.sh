#!/bin/bash

echo "Checking for system extension activity..."
echo

# Check for sysextd logs
echo "=== System Extension Daemon Logs ==="
log show --predicate 'process == "sysextd"' --style syslog --last 2m | grep -i "gige\|camera\|lukechang" | tail -20

echo
echo "=== Extension Kit Logs ==="
log show --predicate 'subsystem == "com.apple.extensionKit"' --style syslog --last 2m | grep -i "gige\|camera\|lukechang" | tail -20

echo
echo "=== App Logs ==="
log show --predicate 'process == "GigEVirtualCamera"' --style syslog --last 2m | tail -20

echo
echo "=== System Extension Errors ==="
log show --predicate 'eventMessage CONTAINS "system extension" OR eventMessage CONTAINS "SystemExtension"' --style syslog --last 2m | tail -20