#!/bin/bash

echo "=== Verifying Build and Testing Frame Flow ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "GigEVirtualCamera.app" -path "*/Debug/*" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Debug build not found${NC}"
    exit 1
fi

echo "Found app at: $APP_PATH"

# Check if the binary contains property listener symbols
echo ""
echo "Checking for property listener code in binary..."
if strings "$APP_PATH/Contents/MacOS/GigEVirtualCamera" | grep -q "CMIOPropertyListener"; then
    echo -e "${GREEN}✅ Binary contains CMIOPropertyListener code${NC}"
else
    echo -e "${RED}❌ Binary does NOT contain CMIOPropertyListener code${NC}"
    echo "The app may not have been built with the latest code!"
    exit 1
fi

# Check for sink connector
if strings "$APP_PATH/Contents/MacOS/GigEVirtualCamera" | grep -q "CMIOSinkConnector"; then
    echo -e "${GREEN}✅ Binary contains CMIOSinkConnector code${NC}"
else
    echo -e "${RED}❌ Binary does NOT contain CMIOSinkConnector code${NC}"
fi

# Launch the app
echo ""
echo "Launching app..."
open "$APP_PATH"
sleep 3

# Get the app PID
APP_PID=$(pgrep -f "GigEVirtualCamera.app" | head -1)
if [ -z "$APP_PID" ]; then
    echo -e "${RED}❌ App failed to launch${NC}"
    exit 1
fi

echo -e "${GREEN}✅ App launched (PID: $APP_PID)${NC}"

# Monitor logs for property listener
echo ""
echo "Monitoring for property listener initialization (10 seconds)..."
echo "Looking for patterns:"
echo "  - 'CMIOPropertyListener init'"
echo "  - 'CMIOSinkConnector initialized'"
echo "  - 'Setting up CMIO property listener'"

# Create a temp file to capture logs
TEMP_LOG=$(mktemp)

# Start log stream in background
log stream --predicate "processID == $APP_PID" --info > "$TEMP_LOG" 2>&1 &
LOG_PID=$!

# Wait and check
sleep 10
kill $LOG_PID 2>/dev/null

# Check for property listener initialization
if grep -q -E "(CMIOPropertyListener|CMIOSinkConnector|property listener)" "$TEMP_LOG"; then
    echo -e "${GREEN}✅ Property listener code is running!${NC}"
    echo "Found messages:"
    grep -E "(CMIOPropertyListener|CMIOSinkConnector|property listener)" "$TEMP_LOG" | head -5
else
    echo -e "${RED}❌ No property listener activity detected${NC}"
    echo ""
    echo "App may be using old code. Checking app logs for any activity..."
    grep -i "camera\|gige\|aravis" "$TEMP_LOG" | head -10
fi

# Clean up
rm -f "$TEMP_LOG"

echo ""
echo "=== Next Steps ==="
echo "1. If property listener is not running, rebuild with:"
echo "   xcodebuild -scheme GigEVirtualCamera -configuration Debug clean build"
echo ""
echo "2. Make sure to install the freshly built app"
echo ""
echo "3. Monitor live logs with:"
echo "   ./Scripts/monitor_frame_flow.sh"