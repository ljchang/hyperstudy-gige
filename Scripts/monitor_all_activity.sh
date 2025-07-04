#!/bin/bash

echo "Monitoring all GigE Virtual Camera activity..."
echo "Select 'GigE Virtual Camera' in Photo Booth now!"
echo ""

# Monitor in real-time
log stream --predicate '
    process == "GigEVirtualCamera" OR 
    process == "GigEVirtualCameraExtension" OR 
    eventMessage CONTAINS[c] "gige" OR 
    eventMessage CONTAINS "virtual camera" OR
    eventMessage CONTAINS "4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4" OR
    subsystem == "com.lukechang.GigEVirtualCamera" OR
    subsystem == "com.apple.cmio"
' --info 2>&1 | grep -v "log:" | while read line; do
    # Highlight important messages
    if echo "$line" | grep -q -E "(CMIOPropertyListener|CMIOSinkConnector|initialized|started|discovered|connected|sink|stream)"; then
        echo "🎯 $line"
    elif echo "$line" | grep -q -i "error"; then
        echo "❌ $line"
    elif echo "$line" | grep -q "Extension"; then
        echo "📦 $line"
    else
        echo "$line"
    fi
done