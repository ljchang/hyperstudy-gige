#!/bin/bash

echo "=== CMIO Extension Launch Diagnostic ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check extension bundle and executable
echo "1. Checking extension bundle structure..."
EXTENSION_BUNDLE="/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
if [ -d "$EXTENSION_BUNDLE" ]; then
    echo -e "${GREEN}✅ Extension bundle exists${NC}"
    echo "   Bundle path: $EXTENSION_BUNDLE"
    
    # Check executable
    EXECUTABLE="$EXTENSION_BUNDLE/Contents/MacOS/GigECameraExtension"
    if [ -f "$EXECUTABLE" ]; then
        echo -e "${GREEN}✅ Extension executable exists${NC}"
        echo "   Executable: GigECameraExtension"
        
        # Check code signing
        echo ""
        echo "2. Checking code signing..."
        codesign -dv "$EXECUTABLE" 2>&1 | grep -E "Identifier|TeamIdentifier|Authority" | head -5
        
        # Check entitlements
        echo ""
        echo "3. Checking entitlements..."
        codesign -d --entitlements - "$EXECUTABLE" 2>&1 | grep -A10 "<dict>" | head -15
    else
        echo -e "${RED}❌ Extension executable not found${NC}"
    fi
else
    echo -e "${RED}❌ Extension bundle not found${NC}"
fi

echo ""
echo "4. Checking system extension registration..."
systemextensionsctl list | grep -A5 "com.lukechang" || echo -e "${RED}❌ Extension not registered${NC}"

echo ""
echo "5. Checking for running extension process..."
# Look for the correct process name
if pgrep -f "GigECameraExtension" > /dev/null; then
    echo -e "${GREEN}✅ Extension process is running${NC}"
    ps aux | grep -i "GigECameraExtension" | grep -v grep
else
    echo -e "${YELLOW}⚠️  Extension process not running (this is normal if no client is connected)${NC}"
fi

echo ""
echo "6. Checking CMIO registration..."
if system_profiler SPCameraDataType | grep -q "GigE Virtual Camera"; then
    echo -e "${GREEN}✅ Virtual camera is registered with macOS${NC}"
    system_profiler SPCameraDataType | grep -A3 "GigE Virtual Camera"
else
    echo -e "${RED}❌ Virtual camera not registered${NC}"
fi

echo ""
echo "7. Testing extension launch..."
echo -e "${YELLOW}Opening Photo Booth to trigger extension...${NC}"
open -a "Photo Booth" 2>/dev/null || echo -e "${RED}Photo Booth not found${NC}"

# Monitor for extension launch with correct process name
echo "Monitoring for extension process (10 seconds)..."
for i in {1..20}; do
    if pgrep -f "GigECameraExtension" > /dev/null; then
        echo -e "${GREEN}✅ Extension launched successfully!${NC}"
        echo "Process details:"
        ps aux | grep -i "GigECameraExtension" | grep -v grep
        break
    fi
    sleep 0.5
    echo -n "."
done
echo ""

if ! pgrep -f "GigECameraExtension" > /dev/null; then
    echo -e "${RED}❌ Extension did not launch${NC}"
    
    echo ""
    echo "8. Checking for launch errors in system logs..."
    echo "Recent CMIO errors:"
    log show --predicate 'subsystem == "com.apple.cmio"' --last 30s --info 2>/dev/null | grep -i "error\|fail" | tail -5
    
    echo ""
    echo "Recent extension errors:"
    log show --predicate 'eventMessage CONTAINS "com.lukechang.GigEVirtualCamera"' --last 30s --info 2>/dev/null | grep -i "error\|fail\|denied" | tail -5
fi

echo ""
echo "9. Checking NSLog output from extension..."
log show --predicate 'eventMessage CONTAINS "GigEVirtualCamera Extension"' --last 1m --info 2>/dev/null | grep "🔴" | tail -10 || echo "No NSLog messages found from extension"

echo ""
echo "=== Diagnostic Complete ==="
echo ""
echo "Summary:"
if pgrep -f "GigECameraExtension" > /dev/null; then
    echo -e "${GREEN}Extension is running - check frame flow issues${NC}"
else
    echo -e "${RED}Extension is not running - check launch issues above${NC}"
fi