#!/bin/bash

echo "=== Monitoring Frame Sender Queue Logs ==="
echo "Press Ctrl+C to stop"
echo

# Monitor for queue-related messages
log stream --predicate 'process == "GigEVirtualCamera" AND (message CONTAINS "queue" OR message CONTAINS "Queue" OR message CONTAINS "waiting" OR message CONTAINS "refresh")' --style compact | grep -E "queue|Queue|waiting|refresh|obtained"