#!/bin/bash

echo "Checking IOSurface Frame Sharing Status"
echo "======================================"
echo ""

# Check shared UserDefaults
echo "Current frame data in shared UserDefaults:"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera currentFrameIndex 2>/dev/null || echo "No frame index"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera currentFrameSurfaceID 2>/dev/null || echo "No surface ID"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera frameWidth 2>/dev/null || echo "No width"
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera frameHeight 2>/dev/null || echo "No height"

echo ""
echo "Monitoring for updates (press Ctrl+C to stop)..."
echo ""

# Monitor for changes
while true; do
    FRAME_INDEX=$(defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera currentFrameIndex 2>/dev/null)
    SURFACE_ID=$(defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera currentFrameSurfaceID 2>/dev/null)
    
    if [ -n "$FRAME_INDEX" ] && [ -n "$SURFACE_ID" ]; then
        echo "$(date '+%H:%M:%S') - Frame: $FRAME_INDEX, IOSurface: $SURFACE_ID"
    fi
    
    sleep 0.5
done