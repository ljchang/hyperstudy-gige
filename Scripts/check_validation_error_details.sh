#!/bin/bash

echo "=== Checking Validation Error Details ==="
echo
echo "1. Recent sysextd errors:"
log show --predicate 'process == "sysextd" AND message CONTAINS "validation"' --last 5m | tail -20

echo
echo "2. Recent extension-related errors:"
log show --predicate '(process == "sysextd" OR process == "GigEVirtualCamera") AND (message CONTAINS "failed" OR message CONTAINS "error" OR message CONTAINS "Invalid")' --last 5m | tail -30

echo
echo "3. Checking for specific validation issues:"
log show --predicate 'process == "sysextd"' --last 5m | grep -E "entitlement|provision|signature|bundle|identifier" | tail -20

echo
echo "4. Extension request details:"
log show --predicate 'subsystem == "com.apple.extensionKit" OR subsystem == "com.apple.sysextd"' --last 5m | grep -E "GigEVirtualCamera|validation" | tail -20