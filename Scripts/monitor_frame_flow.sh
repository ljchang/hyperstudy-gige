#!/bin/bash

# Monitor frame flow between app and extension
echo "=== Monitoring GigE Virtual Camera Frame Flow ==="
echo "Starting at: $(date)"
echo ""
echo "Legend:"
echo "  📤 App writes frame to IOSurface"
echo "  📥 Extension reads frame from IOSurface" 
echo "  📤 Extension sends frame to CMIO/Photo Booth"
echo ""
echo "Press Ctrl+C to stop..."
echo ""

# Use log stream to monitor in real-time
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND (category == "IOSurfaceFrameWriter" OR category == "FrameCache" OR category == "StreamSource")' --style compact | while read -r line; do
    # Extract timestamp and message
    timestamp=$(echo "$line" | awk '{print $1, $2}')
    
    # Color code and format based on component
    if echo "$line" | grep -q "IOSurfaceFrameWriter"; then
        # App writing frames
        echo -e "\033[32m[APP] $timestamp\033[0m"
        echo "$line" | grep -oE "📤.*" || echo "$line" | grep -oE "Wrote frame.*"
    elif echo "$line" | grep -q "FrameCache"; then
        # Extension reading frames
        echo -e "\033[34m[EXT-CACHE] $timestamp\033[0m"
        echo "$line" | grep -oE "📥.*" || echo "$line" | grep -oE "Cached frame.*"
    elif echo "$line" | grep -q "StreamSource"; then
        # Extension sending frames
        echo -e "\033[35m[EXT-STREAM] $timestamp\033[0m"
        echo "$line" | grep -oE "📤.*" || echo "$line" | grep -oE "Frame #.*"
    fi
    
    echo ""
done