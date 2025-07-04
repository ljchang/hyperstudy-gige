#!/bin/bash

echo "Monitoring for extension NSLog messages..."
echo "Please select 'GigE Virtual Camera' in Photo Booth now!"
echo ""

# Monitor Console.app logs for NSLog messages
log stream --predicate 'eventMessage CONTAINS[c] "GigEVirtualCamera Extension" OR eventMessage CONTAINS "🔴"' --info 2>&1 | while read line; do
    if echo "$line" | grep -q "🔴"; then
        echo "🎯 EXTENSION LOG: $line"
    else
        echo "$line"
    fi
done