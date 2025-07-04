#!/bin/bash

echo "=== GigE Virtual Camera Frame Flow Fix ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Diagnose current state
echo -e "${BLUE}Step 1: Diagnosing current state...${NC}"
echo ""

# Check if processes are running
APP_PID=$(pgrep -f "GigEVirtualCamera.app")
EXT_PID=$(pgrep -f "GigECameraExtension")

if [ -n "$APP_PID" ]; then
    echo -e "${GREEN}✓ App is running (PID: $APP_PID)${NC}"
    
    # Check if it's the debug build with property listener
    if log show --predicate "processID == $APP_PID" --last 1m 2>/dev/null | grep -q "CMIOPropertyListener"; then
        echo -e "${GREEN}✓ App has property listener code${NC}"
    else
        echo -e "${RED}✗ App is running OLD code without property listener${NC}"
        echo -e "${YELLOW}  → Need to rebuild and restart app${NC}"
    fi
else
    echo -e "${RED}✗ App is not running${NC}"
fi

if [ -n "$EXT_PID" ]; then
    echo -e "${GREEN}✓ Extension is running (PID: $EXT_PID)${NC}"
    
    # Check for NSLog output
    if log show --predicate "processID == $EXT_PID" --last 1m 2>/dev/null | grep -q "🔴"; then
        echo -e "${GREEN}✓ Extension has debug logging${NC}"
    else
        echo -e "${YELLOW}⚠ Extension may be old version without debug logs${NC}"
    fi
else
    echo -e "${RED}✗ Extension is not running${NC}"
fi

# Step 2: Check CMIO registration
echo ""
echo -e "${BLUE}Step 2: Checking CMIO registration...${NC}"
if system_profiler SPCameraDataType | grep -q "GigE Virtual Camera"; then
    echo -e "${GREEN}✓ Virtual camera is registered${NC}"
else
    echo -e "${RED}✗ Virtual camera not registered${NC}"
fi

# Step 3: Check current frame flow
echo ""
echo -e "${BLUE}Step 3: Checking current frame flow...${NC}"

# Check if Aravis is streaming
if log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' --last 10s 2>/dev/null | grep -q "AravisBridge: Received frame"; then
    echo -e "${GREEN}✓ Aravis is receiving frames from camera${NC}"
else
    echo -e "${YELLOW}⚠ No Aravis frames detected${NC}"
fi

# Check if sink connector is active
if log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' --last 10s 2>/dev/null | grep -q "CMIOSinkConnector"; then
    echo -e "${GREEN}✓ CMIOSinkConnector is active${NC}"
else
    echo -e "${RED}✗ CMIOSinkConnector not active${NC}"
fi

# Step 4: Fix recommendations
echo ""
echo -e "${BLUE}Step 4: Recommended fixes...${NC}"
echo ""

NEEDS_REBUILD=false

# Check if app needs rebuild
if [ -n "$APP_PID" ]; then
    if ! log show --predicate "processID == $APP_PID" --last 1m 2>/dev/null | grep -q "CMIOPropertyListener"; then
        NEEDS_REBUILD=true
        echo -e "${YELLOW}1. App needs to be rebuilt with latest code:${NC}"
        echo "   - Kill current app: killall GigEVirtualCamera"
        echo "   - Rebuild: cd /Users/lukechang/Github/hyperstudy-gige && xcodebuild -scheme GigEVirtualCamera -configuration Debug"
        echo "   - Reinstall: ./Scripts/install_app.sh"
        echo ""
    fi
fi

# Check if extension needs update
if [ -n "$EXT_PID" ]; then
    if ! log show --predicate "processID == $EXT_PID" --last 1m 2>/dev/null | grep -q "🔴"; then
        echo -e "${YELLOW}2. Extension may need update:${NC}"
        echo "   - The extension will be updated when you rebuild the app"
        echo ""
    fi
fi

# Check frame flow issue
echo -e "${YELLOW}3. To test frame flow:${NC}"
echo "   a. Ensure a GigE camera is connected (or use Test Camera)"
echo "   b. Open Photo Booth"
echo "   c. Select 'GigE Virtual Camera'"
echo "   d. Monitor logs: ./Scripts/monitor_frame_flow.sh"
echo ""

# Step 5: Quick fix attempt
if [ "$NEEDS_REBUILD" = true ]; then
    echo -e "${BLUE}Step 5: Quick fix option...${NC}"
    echo ""
    echo "Run this command to rebuild and restart:"
    echo ""
    echo -e "${GREEN}./Scripts/rebuild_and_test.sh${NC}"
else
    echo -e "${BLUE}Step 5: Testing current setup...${NC}"
    echo ""
    echo "Opening Photo Booth for testing..."
    open -a "Photo Booth" 2>/dev/null || echo "Photo Booth not found"
    
    echo ""
    echo "Monitoring for 5 seconds..."
    for i in {1..5}; do
        if log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' --last 2s 2>/dev/null | grep -q "Sink stream discovered via callback"; then
            echo -e "${GREEN}✓ Property listener detected sink stream!${NC}"
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
fi

echo ""
echo "=== Diagnostic Complete ==="