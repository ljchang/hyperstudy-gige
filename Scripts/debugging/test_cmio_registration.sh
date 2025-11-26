#!/bin/bash

echo "=== CMIO Registration Test Script ==="
echo "This script performs a comprehensive test of CMIO registration"
echo

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results storage
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -n "Testing: $test_name... "
    
    result=$(eval "$test_command" 2>&1)
    
    if [[ "$result" == *"$expected_result"* ]]; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Expected: $expected_result"
        echo "  Got: $result" | head -3
        ((TESTS_FAILED++))
        return 1
    fi
}

# 1. App Installation Test
echo -e "\n${BLUE}=== Installation Tests ===${NC}"
run_test "App installed in /Applications" \
    "test -d /Applications/GigEVirtualCamera.app && echo 'installed'" \
    "installed"

run_test "System Extension bundle exists" \
    "test -d /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension && echo 'exists'" \
    "exists"

# 2. Code Signing Tests
echo -e "\n${BLUE}=== Code Signing Tests ===${NC}"
run_test "App is properly signed" \
    "codesign --verify /Applications/GigEVirtualCamera.app 2>&1 && echo 'valid'" \
    "valid"

run_test "Extension is properly signed" \
    "codesign --verify /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 && echo 'valid'" \
    "valid"

# 3. Entitlement Tests
echo -e "\n${BLUE}=== Entitlement Tests ===${NC}"
run_test "App has system extension install entitlement" \
    "codesign -d --entitlements - /Applications/GigEVirtualCamera.app 2>&1 | grep 'com.apple.developer.system-extension.install'" \
    "com.apple.developer.system-extension.install"

run_test "Extension has camera entitlement" \
    "codesign -d --entitlements - /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep 'com.apple.security.device.camera'" \
    "com.apple.security.device.camera"

# 4. System Extension Tests
echo -e "\n${BLUE}=== System Extension Tests ===${NC}"
run_test "System extension is installed" \
    "systemextensionsctl list | grep 'com.lukechang.GigEVirtualCamera.Extension'" \
    "com.lukechang.GigEVirtualCamera.Extension"

# 5. CMIO Registration Tests
echo -e "\n${BLUE}=== CMIO Registration Tests ===${NC}"
run_test "Camera appears in system profiler" \
    "system_profiler SPCameraDataType | grep 'GigE Virtual Camera'" \
    "GigE Virtual Camera"

# 6. Process Tests
echo -e "\n${BLUE}=== Process Tests ===${NC}"
run_test "Extension process is running" \
    "ps aux | grep -v grep | grep GigECameraExtension" \
    "GigECameraExtension"

# 7. Log Tests
echo -e "\n${BLUE}=== Log Analysis ===${NC}"
echo "Checking for recent CMIO errors..."
CMIO_ERRORS=$(log show --predicate 'subsystem == "com.apple.cmio" AND messageType == error' --style syslog --last 5m 2>/dev/null | grep -i "gige\|lukechang" | wc -l)
if [ "$CMIO_ERRORS" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} No CMIO errors found"
else
    echo -e "  ${YELLOW}⚠${NC} Found $CMIO_ERRORS CMIO error(s) in logs"
fi

# 8. Camera Availability Test
echo -e "\n${BLUE}=== Camera Availability Test ===${NC}"
echo "Testing with ffmpeg (if available)..."
if command -v ffmpeg &> /dev/null; then
    CAMERAS=$(ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep "AVFoundation video devices" -A 20 | grep -i "gige")
    if [[ ! -z "$CAMERAS" ]]; then
        echo -e "  ${GREEN}✓${NC} Camera found in AVFoundation devices"
        echo "  $CAMERAS"
    else
        echo -e "  ${RED}✗${NC} Camera not found in AVFoundation devices"
    fi
else
    echo "  ffmpeg not installed, skipping AVFoundation test"
fi

# Summary
echo -e "\n${BLUE}=== Test Summary ===${NC}"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed! Your CMIO extension should be working.${NC}"
else
    echo -e "\n${YELLOW}Some tests failed. See recommendations below:${NC}"
    
    echo -e "\n${BLUE}=== Recommendations ===${NC}"
    echo "1. If system extension is not installed:"
    echo "   - Launch the app and click 'Install Extension'"
    echo "   - Grant permission when prompted"
    echo
    echo "2. If camera is not appearing:"
    echo "   - Enable developer mode: sudo systemextensionsctl developer on"
    echo "   - Restart your Mac"
    echo "   - Check System Settings > General > Login Items & Extensions"
    echo
    echo "3. For code signing issues:"
    echo "   - Ensure you have valid provisioning profiles"
    echo "   - Run: ./Scripts/build_release.sh"
    echo
    echo "4. Check detailed logs:"
    echo "   - Open Console.app"
    echo "   - Filter by 'GigE' or 'cmio'"
fi

echo -e "\n${GREEN}Test completed!${NC}"