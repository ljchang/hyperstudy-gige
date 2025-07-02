#!/bin/bash

echo "=== Testing Test Pattern in Photo Booth ==="
echo
echo "Instructions:"
echo "1. Make sure GigEVirtualCamera app is running"
echo "2. Open Photo Booth"
echo "3. Select 'GigE Virtual Camera' from the camera menu"
echo "4. You should see a moving gradient test pattern"
echo
echo "Starting monitoring for test pattern generation..."
echo

# Open Photo Booth
open -a "Photo Booth"

# Monitor extension logs for test pattern
echo "Monitoring extension logs..."
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND (message CONTAINS "test" OR message CONTAINS "Test" OR message CONTAINS "Generated")' --style compact