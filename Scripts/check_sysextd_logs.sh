#!/bin/bash

echo "=== Checking sysextd logs for errors ==="
echo "Looking for recent errors..."
echo

# Check the last 2 minutes of logs
log show --predicate 'process == "sysextd"' --last 2m | grep -E "com.lukechang|error|fail|denied|reject" | tail -50

echo
echo "=== Checking for specific extension errors ==="
log show --predicate 'process == "sysextd" AND eventMessage CONTAINS "com.lukechang.GigEVirtualCamera"' --last 5m