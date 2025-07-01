#!/bin/bash

echo "=== Debugging CMIO Device Discovery ==="
echo ""

# Check if extension is loaded
echo "1. Checking if extension is loaded:"
systemextensionsctl list | grep -i gige
echo ""

# Check system logs for CMIO device registration
echo "2. Checking for CMIO device registration in system logs:"
log show --predicate 'eventMessage contains "CMIO" OR eventMessage contains "GigE Virtual Camera"' --last 5m | grep -E "(registered|device|stream|sink|source)" | tail -20
echo ""

# Check for our specific device
echo "3. Looking for our virtual camera device:"
log show --predicate 'eventMessage contains "7A96E4B8-1A7B-4F8C-9E3D-5C2A8B4D9F0E"' --last 5m | tail -10
echo ""

# Check CoreMediaIO subsystem logs
echo "4. CoreMediaIO subsystem logs:"
log show --predicate 'subsystem == "com.apple.cmio"' --last 2m | grep -i "gige" | tail -20
echo ""

# Check for sink/source stream creation
echo "5. Sink/Source stream creation logs:"
log show --predicate 'eventMessage contains "sink" OR eventMessage contains "source"' --last 2m | grep -i "stream" | tail -20