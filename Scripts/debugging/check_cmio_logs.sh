#!/bin/bash

echo "=== Checking CMIOExtension Logs ==="
echo

# Check for CMIO extension loading
echo "1. CMIO Extension Loading:"
log show --predicate 'subsystem == "com.apple.cmio"' --style syslog --last 10m | grep -i "extension\|gige" | tail -20

echo
echo "2. Extension Service Logs:"
log show --predicate 'process == "ExtensionKit"' --style syslog --last 10m | grep -i "gige\|camera" | tail -20

echo
echo "3. Camera Process Logs:"
log show --predicate 'process == "appleh13camerad"' --style syslog --last 10m | grep -i "gige\|extension" | tail -20

echo
echo "4. Any GigE Related Errors:"
log show --predicate 'eventMessage CONTAINS "GigE" OR eventMessage CONTAINS "lukechang"' --style syslog --last 10m | tail -30