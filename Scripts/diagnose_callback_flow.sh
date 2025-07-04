#!/bin/bash
#
# diagnose_callback_flow.sh
# Comprehensive diagnostic for callback-based CMIO frame flow
#

set -e

echo "=============================================="
echo "CMIO Callback Flow Diagnostic"
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check process
check_process() {
    local process_name=$1
    if pgrep -f "$process_name" > /dev/null; then
        local pid=$(pgrep -f "$process_name" | head -1)
        echo -e "${GREEN}✅ $process_name is running (PID: $pid)${NC}"
        return 0
    else
        echo -e "${RED}❌ $process_name is NOT running${NC}"
        return 1
    fi
}

# Function to check recent logs
check_log_pattern() {
    local pattern=$1
    local description=$2
    local category=$3
    
    if [ -n "$category" ]; then
        local predicate="subsystem == \"com.lukechang.GigEVirtualCamera\" AND category == \"$category\""
    else
        local predicate="subsystem == \"com.lukechang.GigEVirtualCamera\""
    fi
    
    if log show --last 30s --predicate "$predicate" 2>/dev/null | grep -q "$pattern"; then
        echo -e "${GREEN}✅ $description${NC}"
        # Show the actual log line
        log show --last 30s --predicate "$predicate" 2>/dev/null | grep "$pattern" | tail -1 | sed 's/^/   /'
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

# 1. Check processes
echo -e "${BLUE}1. Process Status:${NC}"
echo "==================="
check_process "GigEVirtualCamera.app"
APP_RUNNING=$?

check_process "GigEVirtualCameraExtension"
EXT_RUNNING=$?

# Check if Photo Booth is running
if pgrep -f "Photo Booth" > /dev/null; then
    echo -e "${GREEN}✅ Photo Booth is running${NC}"
    PHOTOBOOTH_RUNNING=0
else
    echo -e "${YELLOW}⚠️  Photo Booth is not running${NC}"
    PHOTOBOOTH_RUNNING=1
fi

echo ""

# 2. Check Property Listener
echo -e "${BLUE}2. Property Listener Status:${NC}"
echo "=============================="
check_log_pattern "CMIOPropertyListener initialized" "Property listener initialized" "CMIOPropertyListener"
check_log_pattern "CMIO property listener started successfully" "Property listener started" "CMIOPropertyListener"
check_log_pattern "Starting CMIO property listeners" "Property listeners active" "CMIOPropertyListener"

echo ""

# 3. Check Device Discovery
echo -e "${BLUE}3. Device Discovery:${NC}"
echo "====================="
check_log_pattern "Found device: 4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4" "Virtual camera device found" "CMIOPropertyListener"
check_log_pattern "Virtual camera device discovered" "Device discovery callback fired" "CMIOPropertyListener"
check_log_pattern "Target device with ID:" "Device registered with listener" "CMIOPropertyListener"

echo ""

# 4. Check Sink Stream Discovery
echo -e "${BLUE}4. Sink Stream Discovery:${NC}"
echo "=========================="
SINK_DISCOVERED=0
if check_log_pattern "Sink stream discovered via callback" "Sink stream discovered" "CMIOSinkConnector"; then
    SINK_DISCOVERED=1
fi
check_log_pattern "Found sink stream: GigE Camera Input" "Correct sink stream identified" "CMIOPropertyListener"
check_log_pattern "New sink stream discovered" "Stream added to known streams" "CMIOPropertyListener"

echo ""

# 5. Check Sink Connection
echo -e "${BLUE}5. Sink Stream Connection:${NC}"
echo "==========================="
SINK_CONNECTED=0
if check_log_pattern "Successfully connected to virtual camera sink stream via property listener" "Sink connection successful" "CMIOSinkConnector"; then
    SINK_CONNECTED=1
fi
check_log_pattern "Successfully obtained buffer queue" "Buffer queue acquired" "CMIOSinkConnector"
check_log_pattern "Successfully started sink stream" "Sink stream started" "CMIOSinkConnector"

echo ""

# 6. Check Extension State
echo -e "${BLUE}6. Extension Stream State:${NC}"
echo "==========================="
check_log_pattern "Starting sink stream" "Extension sink stream started" "SinkStream"
check_log_pattern "Starting source stream" "Extension source stream started" "SourceStream"
check_log_pattern "Client authorized to start" "Client authorized" ""
check_log_pattern "signaled app to start sending frames" "App signaled for frames" "StreamState"

echo ""

# 7. Check Aravis/GigE Camera
echo -e "${BLUE}7. Camera Connection:${NC}"
echo "======================"
check_log_pattern "Connected to camera" "Camera connected" "CameraManager"
check_log_pattern "Starting camera streaming" "Camera streaming started" ""
check_log_pattern "Streaming started successfully" "GigE streaming active" "GigECameraManager"

echo ""

# 8. Check Frame Flow
echo -e "${BLUE}8. Frame Flow:${NC}"
echo "==============="
FRAMES_FLOWING=0
if check_log_pattern "Sent frame #" "Frames being sent to sink" "CMIOSinkConnector"; then
    FRAMES_FLOWING=1
    # Get frame count
    FRAME_COUNT=$(log show --last 10s --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND message CONTAINS "Sent frame #"' 2>/dev/null | grep -o "Sent frame #[0-9]*" | tail -1 | grep -o "[0-9]*" || echo "0")
    if [ "$FRAME_COUNT" != "0" ]; then
        echo -e "   ${GREEN}Frame count: $FRAME_COUNT${NC}"
    fi
fi

check_log_pattern "Received frame #" "Extension receiving frames" "SinkStream"
check_log_pattern "First frame sent to CMIO sink" "Initial frame sent" "CameraManager"

echo ""

# 9. Diagnose Issues
echo -e "${BLUE}9. Diagnosis:${NC}"
echo "=============="

if [ $APP_RUNNING -eq 0 ] && [ $EXT_RUNNING -eq 0 ]; then
    if [ $SINK_DISCOVERED -eq 0 ]; then
        echo -e "${RED}❌ Issue: Sink stream not discovered by property listener${NC}"
        echo "   - Check if extension is creating sink stream"
        echo "   - Verify device UID matches between app and extension"
        echo "   - Check for property listener registration errors"
    elif [ $SINK_CONNECTED -eq 0 ]; then
        echo -e "${RED}❌ Issue: Sink stream discovered but connection failed${NC}"
        echo "   - Check buffer queue acquisition"
        echo "   - Verify stream can be started"
        echo "   - Look for retry attempts in logs"
    elif [ $FRAMES_FLOWING -eq 0 ]; then
        echo -e "${RED}❌ Issue: Sink connected but no frames flowing${NC}"
        echo "   - Check if Aravis camera is connected and streaming"
        echo "   - Verify frame handler is registered"
        echo "   - Check for frame enqueue errors"
    else
        echo -e "${GREEN}✅ Frame flow appears to be working${NC}"
        echo "   - Frames are being sent to sink"
        echo "   - Check if Photo Booth is receiving them"
    fi
else
    echo -e "${RED}❌ Basic requirements not met${NC}"
    [ $APP_RUNNING -ne 0 ] && echo "   - App is not running"
    [ $EXT_RUNNING -ne 0 ] && echo "   - Extension is not running"
fi

echo ""

# 10. Real-time monitoring
echo -e "${BLUE}10. Starting real-time monitoring...${NC}"
echo "======================================="
echo "Watching for callback events and frame flow..."
echo "(Press Ctrl+C to stop)"
echo ""

# Monitor key events
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND (
    message CONTAINS "property listener" OR 
    message CONTAINS "discovered via callback" OR 
    message CONTAINS "Sink stream" OR
    message CONTAINS "Successfully connected" OR
    message CONTAINS "Sent frame" OR
    message CONTAINS "Received frame" OR
    message CONTAINS "Starting Aravis streaming" OR
    message CONTAINS "Failed to" OR
    message CONTAINS "Error" OR
    category == "CMIOPropertyListener" OR
    category == "CMIOSinkConnector"
)' --info --style compact