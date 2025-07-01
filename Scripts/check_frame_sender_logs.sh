#!/bin/bash

echo "=== Check Frame Sender Logs ==="
echo

# Check the last 30 seconds of logs
echo "Recent FrameSender logs:"
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "FrameSender"' --style compact | head -20