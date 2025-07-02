#\!/bin/bash

echo "Checking GigE Virtual Camera Frame Flow"
echo "======================================="

# Check if test camera is connected
echo -e "\n1. Checking camera connection status..."
defaults read com.lukechang.GigEVirtualCamera lastConnectedCamera 2>/dev/null || echo "No last connected camera"

# Check shared defaults for frame data
echo -e "\n2. Checking shared frame data..."
defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera 2>/dev/null || echo "No shared frame data"

# Monitor real-time logs
echo -e "\n3. Monitoring frame flow (press Ctrl+C to stop)..."
echo "Looking for:"
echo "  - 'Starting acquisition' (camera starts)"
echo "  - 'Wrote frame' (app writes frame)"
echo "  - 'Cached frame' (extension reads frame)"
echo "  - 'Frame #' (extension sends frame)"
echo ""

log stream --predicate 'eventMessage contains "frame" OR eventMessage contains "Frame" OR eventMessage contains "acquisition" OR eventMessage contains "streaming"' --info | grep -E "(GigEVirtualCamera|GigECameraExtension)"
