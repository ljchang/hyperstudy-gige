#!/bin/bash

# Test script to verify CMIO sink/source frame flow
# This monitors the complete frame flow from app -> sink -> extension -> source -> client

echo "=== CMIO Sink/Source Frame Flow Test ==="
echo "This script monitors the frame flow through the virtual camera"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if virtual camera is installed
echo -e "${BLUE}1. Checking if GigE Virtual Camera is installed...${NC}"
if system_profiler SPCameraDataType | grep -q "GigE Virtual Camera"; then
    echo -e "${GREEN}✓ Virtual camera found in system${NC}"
else
    echo -e "${RED}✗ Virtual camera not found. Please install the extension first.${NC}"
    exit 1
fi

# Check extension status
echo -e "\n${BLUE}2. Checking extension status...${NC}"
systemextensionsctl list | grep -A 3 "com.lukechang.GigEVirtualCamera"

# Check App Groups communication
echo -e "\n${BLUE}3. Checking App Groups communication...${NC}"
APP_GROUP_PATH="$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera"
if [ -d "$APP_GROUP_PATH" ]; then
    echo -e "${GREEN}✓ App Group container exists${NC}"
    
    # Check for stream state
    if defaults read "$APP_GROUP_PATH/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist" StreamState 2>/dev/null; then
        echo "Current stream state:"
        defaults read "$APP_GROUP_PATH/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist" StreamState
    else
        echo "No stream state found (extension may not be running)"
    fi
else
    echo -e "${YELLOW}⚠ App Group container not found${NC}"
fi

# Function to monitor logs
monitor_logs() {
    echo -e "\n${BLUE}4. Starting log monitoring...${NC}"
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    # Create temp files for each log stream
    SINK_LOG=$(mktemp)
    SOURCE_LOG=$(mktemp)
    BRIDGE_LOG=$(mktemp)
    APP_LOG=$(mktemp)
    
    # Start monitoring different components in background
    log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category == "SinkStream"' > "$SINK_LOG" &
    SINK_PID=$!
    
    log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category == "SourceStream"' > "$SOURCE_LOG" &
    SOURCE_PID=$!
    
    log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension" AND category == "Device"' > "$BRIDGE_LOG" &
    BRIDGE_PID=$!
    
    log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "CMIOSinkConnector"' > "$APP_LOG" &
    APP_PID=$!
    
    # Monitor all logs
    log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension"' | while read -r line; do
        if [[ $line == *"CMIOSinkConnector"* ]]; then
            echo -e "${YELLOW}[APP->SINK]${NC} $line"
        elif [[ $line == *"SinkStream"* ]] && [[ $line == *"Received frame"* ]]; then
            echo -e "${GREEN}[SINK RECV]${NC} $line"
        elif [[ $line == *"Device"* ]] && [[ $line == *"bridging to source"* ]]; then
            echo -e "${BLUE}[BRIDGE]${NC} $line"
        elif [[ $line == *"SourceStream"* ]] && [[ $line == *"send"* ]]; then
            echo -e "${GREEN}[SOURCE->CLIENT]${NC} $line"
        elif [[ $line == *"Client connected"* ]]; then
            echo -e "${GREEN}[CLIENT CONNECT]${NC} $line"
        elif [[ $line == *"Client disconnected"* ]]; then
            echo -e "${RED}[CLIENT DISCONNECT]${NC} $line"
        elif [[ $line == *"Error"* ]] || [[ $line == *"error"* ]]; then
            echo -e "${RED}[ERROR]${NC} $line"
        elif [[ $line == *"StreamState"* ]]; then
            echo -e "${BLUE}[STATE]${NC} $line"
        fi
    done
    
    # Cleanup on exit
    trap "kill $SINK_PID $SOURCE_PID $BRIDGE_PID $APP_PID 2>/dev/null; rm -f $SINK_LOG $SOURCE_LOG $BRIDGE_LOG $APP_LOG" EXIT
}

# Instructions
echo -e "\n${YELLOW}Instructions:${NC}"
echo "1. Run this script to start monitoring"
echo "2. Open the GigE Virtual Camera app"
echo "3. Click 'Start Virtual Camera' button"
echo "4. Connect a GigE camera if available"
echo "5. Open QuickTime Player or Photo Booth"
echo "6. Select 'GigE Virtual Camera' as the camera source"
echo ""
echo "Expected flow:"
echo "  App -> CMIO Sink -> Extension Bridge -> CMIO Source -> Client"
echo ""

# Start monitoring
monitor_logs