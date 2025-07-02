#!/bin/bash

echo "=== Monitoring Extension NSLog Output ==="
echo ""
echo "1. Please do the following in the app:"
echo "   - Uninstall the extension"
echo "   - Install the extension again"
echo ""
echo "2. Monitoring for GigEVirtualCamera logs..."
echo ""

# Monitor for our specific NSLog messages
log stream --predicate 'eventMessage CONTAINS "GigEVirtualCamera"' --info --style compact