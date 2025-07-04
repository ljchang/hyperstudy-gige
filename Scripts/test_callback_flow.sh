#!/bin/bash
#
# test_callback_flow.sh
# Tests the CMIO callback-based sink stream detection
#

set -e

echo "================================================"
echo "CMIO Callback-Based Sink Stream Detection Test"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if process is running
check_process() {
    local process_name=$1
    if pgrep -f "$process_name" > /dev/null; then
        echo -e "${GREEN}✅ $process_name is running${NC}"
        return 0
    else
        echo -e "${RED}❌ $process_name is NOT running${NC}"
        return 1
    fi
}

# Function to check recent logs
check_logs() {
    local pattern=$1
    local description=$2
    
    if log show --last 30s --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' 2>/dev/null | grep -q "$pattern"; then
        echo -e "${GREEN}✅ $description${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $description - Not found in last 30 seconds${NC}"
        return 1
    fi
}

# 1. Check prerequisites
echo "1. Checking Prerequisites..."
echo "----------------------------"

check_process "GigEVirtualCamera"
APP_RUNNING=$?

check_process "GigECameraExtension"
EXT_RUNNING=$?

echo ""

# 2. Check property listener initialization
echo "2. Checking Property Listener..."
echo "--------------------------------"

check_logs "CMIOPropertyListener initialized" "Property listener initialized"
check_logs "CMIO property listener started successfully" "Property listener started"
check_logs "Starting CMIO property listeners" "Property listeners active"

echo ""

# 3. Check device discovery
echo "3. Checking Device Discovery..."
echo "-------------------------------"

check_logs "Found device: 4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4" "Virtual camera device found"
check_logs "Virtual camera device discovered" "Device discovery callback fired"

echo ""

# 4. Check sink stream discovery
echo "4. Checking Sink Stream Discovery..."
echo "------------------------------------"

if check_logs "Sink stream discovered via callback" "Sink stream discovered"; then
    check_logs "Found sink stream: GigE Camera Input" "Correct sink stream identified"
    check_logs "Successfully connected to virtual camera sink stream via property listener" "Automatic connection successful"
fi

echo ""

# 5. Check frame flow
echo "5. Checking Frame Flow..."
echo "-------------------------"

if [ $APP_RUNNING -eq 0 ] && [ $EXT_RUNNING -eq 0 ]; then
    # Give it a moment for frames to flow
    sleep 2
    
    if check_logs "Sent frame #" "Frames being sent to sink"; then
        FRAME_COUNT=$(log show --last 10s --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND message CONTAINS "Sent frame #"' 2>/dev/null | grep -o "Sent frame #[0-9]*" | tail -1 | grep -o "[0-9]*" || echo "0")
        if [ "$FRAME_COUNT" != "0" ]; then
            echo -e "${GREEN}✅ Frame count: $FRAME_COUNT${NC}"
        fi
    fi
fi

echo ""

# 6. Monitor real-time activity
echo "6. Real-time Monitoring (Press Ctrl+C to stop)..."
echo "-------------------------------------------------"
echo "Watching for callback events..."
echo ""

# Start monitoring in background
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND (
    message CONTAINS "property listener" OR 
    message CONTAINS "discovered via callback" OR 
    message CONTAINS "Sink stream" OR
    message CONTAINS "Device discovered" OR
    message CONTAINS "Starting Aravis streaming"
)' --info --style compact