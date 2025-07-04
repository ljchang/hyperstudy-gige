#!/bin/bash

echo "=== Rebuilding and Testing GigE Virtual Camera ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Kill existing processes
echo "1. Stopping existing processes..."
killall GigEVirtualCamera 2>/dev/null || echo "   App not running"
killall GigECameraExtension 2>/dev/null || echo "   Extension not running"
sleep 2

# Step 2: Build the app
echo ""
echo "2. Building the app..."
cd /Users/lukechang/Github/hyperstudy-gige
xcodebuild -project GigEVirtualCamera.xcodeproj -scheme GigEVirtualCamera -configuration Debug build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Build succeeded${NC}"

# Step 3: Install the app
echo ""
echo "3. Installing the app..."
# Find the built app
BUILD_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "GigEVirtualCamera.app" -path "*/Debug/*" -type d | head -1)

if [ -z "$BUILD_PATH" ]; then
    echo -e "${RED}❌ Could not find built app${NC}"
    exit 1
fi

echo "   Found app at: $BUILD_PATH"

# Remove old app
sudo rm -rf /Applications/GigEVirtualCamera.app
# Copy new app
sudo cp -R "$BUILD_PATH" /Applications/
echo -e "${GREEN}✅ App installed${NC}"

# Step 4: Launch the app
echo ""
echo "4. Launching the app..."
open /Applications/GigEVirtualCamera.app
sleep 3

# Step 5: Check if extension loads properly
echo ""
echo "5. Checking extension status..."
if pgrep -f "GigECameraExtension" > /dev/null; then
    echo -e "${GREEN}✅ Extension is running${NC}"
    
    # Check for NSLog output
    echo ""
    echo "6. Checking for extension debug logs..."
    log show --predicate 'eventMessage CONTAINS "🔴"' --last 30s --info 2>&1 | grep "🔴" | tail -5
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Extension is logging properly${NC}"
    else
        echo -e "${YELLOW}⚠️  No debug logs from extension - may be old version${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Extension not running yet (this is normal)${NC}"
fi

# Step 6: Test with Photo Booth
echo ""
echo "7. Opening Photo Booth for testing..."
open -a "Photo Booth"
echo -e "${YELLOW}Please select 'GigE Virtual Camera' in Photo Booth${NC}"

# Step 7: Monitor frame flow
echo ""
echo "8. Monitoring frame flow (10 seconds)..."
echo "   Watching for:"
echo "   - Extension signaling need for frames"
echo "   - App responding to signals"
echo "   - Sink connection establishment"
echo "   - Frame transmission"
echo ""

# Run monitoring for 10 seconds
end_time=$(($(date +%s) + 10))
while [ $(date +%s) -lt $end_time ]; do
    # Check if extension is signaling
    if defaults read group.S368GH6KF7.com.lukechang.GigEVirtualCamera StreamState 2>/dev/null | grep -q "streamActive = 1"; then
        echo -e "${GREEN}✓ Extension is signaling need for frames${NC}"
        break
    fi
    sleep 1
done

# Final check
echo ""
echo "9. Final status check..."
./Scripts/test_complete_frame_flow.sh

echo ""
echo "=== Rebuild and Test Complete ==="
echo ""
echo "If video is not showing in Photo Booth:"
echo "1. Check Console.app for any error messages"
echo "2. Run: ./Scripts/monitor_frame_flow.sh"
echo "3. Check system extension permissions in System Settings"