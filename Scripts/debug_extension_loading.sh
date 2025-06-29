#!/bin/bash

# debug_extension_loading.sh - Comprehensive CMIO extension loading diagnostics
# This script performs deep diagnostics to identify why a CMIO extension might not be loading

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="GigEVirtualCamera"
EXTENSION_NAME="GigECameraExtension"
BUNDLE_ID="com.lukechang.GigEVirtualCamera"
EXTENSION_ID="${BUNDLE_ID}.Extension"
APP_PATH="/Applications/${APP_NAME}.app"
EXTENSION_REL_PATH="Contents/PlugIns/${EXTENSION_NAME}.appex"
EXTENSION_PATH="${APP_PATH}/${EXTENSION_REL_PATH}"
EXTENSION_BINARY="${EXTENSION_PATH}/Contents/MacOS/${EXTENSION_NAME}"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}         CMIO Extension Loading Diagnostics${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to check status and print result
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        if [ -n "${3:-}" ]; then
            echo -e "  ${YELLOW}→ $3${NC}"
        fi
    fi
}

# 1. Check Extension Binary Validity
echo -e "${BLUE}1. Extension Binary Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -f "$EXTENSION_BINARY" ]; then
    check_status 0 "Extension binary exists at: $EXTENSION_BINARY"
    
    # Check if executable
    if [ -x "$EXTENSION_BINARY" ]; then
        check_status 0 "Extension binary is executable"
    else
        check_status 1 "Extension binary is NOT executable" "Run: chmod +x \"$EXTENSION_BINARY\""
    fi
    
    # Check file type
    FILE_TYPE=$(file "$EXTENSION_BINARY" | head -1)
    if [[ "$FILE_TYPE" == *"Mach-O"* ]]; then
        check_status 0 "Extension is valid Mach-O binary"
        echo "  File type: $FILE_TYPE"
    else
        check_status 1 "Extension is NOT a valid Mach-O binary"
    fi
    
    # Check architecture
    ARCH=$(lipo -info "$EXTENSION_BINARY" 2>&1)
    echo "  Architecture: $ARCH"
    
    # Check dynamic dependencies
    echo -e "\n  ${YELLOW}Dynamic library dependencies:${NC}"
    otool -L "$EXTENSION_BINARY" | head -10 | sed 's/^/    /'
    
else
    check_status 1 "Extension binary NOT FOUND at expected location" "Build the extension first"
fi

echo ""

# 2. Check Info.plist Structure
echo -e "${BLUE}2. Extension Info.plist Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

EXTENSION_PLIST="${EXTENSION_PATH}/Contents/Info.plist"
if [ -f "$EXTENSION_PLIST" ]; then
    check_status 0 "Extension Info.plist exists"
    
    # Validate plist format
    if plutil -lint "$EXTENSION_PLIST" >/dev/null 2>&1; then
        check_status 0 "Info.plist is valid XML"
    else
        check_status 1 "Info.plist has invalid format"
        plutil -lint "$EXTENSION_PLIST" || true
    fi
    
    # Check required CMIO keys
    echo -e "\n  ${YELLOW}CMIO Extension Configuration:${NC}"
    
    # Extract CMIO configuration
    MACH_SERVICE=$(defaults read "$EXTENSION_PLIST" CMIOExtension 2>/dev/null | grep CMIOExtensionMachServiceName | awk -F'"' '{print $2}' || echo "NOT FOUND")
    CATEGORY=$(defaults read "$EXTENSION_PLIST" CMIOExtension 2>/dev/null | grep CMIOExtensionCategory | awk -F'"' '{print $2}' || echo "NOT FOUND")
    
    echo "    Mach Service Name: $MACH_SERVICE"
    echo "    Extension Category: $CATEGORY"
    
    # Check NSExtension configuration
    echo -e "\n  ${YELLOW}NSExtension Configuration:${NC}"
    POINT_ID=$(defaults read "$EXTENSION_PLIST" NSExtension 2>/dev/null | grep NSExtensionPointIdentifier | awk -F'"' '{print $2}' || echo "NOT FOUND")
    PRINCIPAL_CLASS=$(defaults read "$EXTENSION_PLIST" NSExtension 2>/dev/null | grep NSExtensionPrincipalClass | awk -F'"' '{print $2}' || echo "NOT FOUND")
    
    echo "    Extension Point: $POINT_ID"
    echo "    Principal Class: $PRINCIPAL_CLASS"
    
    # Validate required values
    if [[ "$POINT_ID" == "com.apple.cmio-camera-extension" ]]; then
        check_status 0 "Extension point identifier is correct"
    else
        check_status 1 "Invalid extension point identifier" "Should be: com.apple.cmio-camera-extension"
    fi
else
    check_status 1 "Extension Info.plist NOT FOUND"
fi

echo ""

# 3. Check Code Signing
echo -e "${BLUE}3. Code Signing Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check app signing
echo -e "  ${YELLOW}Main Application:${NC}"
CODESIGN_APP=$(codesign -dv "$APP_PATH" 2>&1)
if [ $? -eq 0 ]; then
    check_status 0 "Application is signed"
    echo "$CODESIGN_APP" | grep -E "Identifier:|TeamIdentifier:|Format:" | sed 's/^/    /'
else
    check_status 1 "Application is NOT properly signed"
fi

# Check extension signing
echo -e "\n  ${YELLOW}Camera Extension:${NC}"
if [ -d "$EXTENSION_PATH" ]; then
    CODESIGN_EXT=$(codesign -dv "$EXTENSION_PATH" 2>&1)
    if [ $? -eq 0 ]; then
        check_status 0 "Extension is signed"
        echo "$CODESIGN_EXT" | grep -E "Identifier:|TeamIdentifier:|Format:" | sed 's/^/    /'
        
        # Verify signature
        if codesign --verify --deep --strict "$EXTENSION_PATH" 2>&1; then
            check_status 0 "Extension signature is valid"
        else
            check_status 1 "Extension signature verification failed"
        fi
    else
        check_status 1 "Extension is NOT properly signed"
    fi
fi

echo ""

# 4. System Extension Status
echo -e "${BLUE}4. System Extension Registration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SYSEXT_STATUS=$(systemextensionsctl list 2>&1 | grep -i "$EXTENSION_NAME" || echo "")
if [ -n "$SYSEXT_STATUS" ]; then
    check_status 0 "Extension is registered with system"
    echo "  Status: $SYSEXT_STATUS"
else
    check_status 1 "Extension NOT registered as system extension" "Install the app properly"
fi

echo ""

# 5. CMIO Subsystem Discovery
echo -e "${BLUE}5. CMIO Subsystem Discovery${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check IORegistry for CMIO devices
echo -e "  ${YELLOW}Checking IORegistry for CMIO devices:${NC}"
IOREG_CMIO=$(ioreg -l -w0 | grep -E "class CMIOUnit|CMIOExtension" | grep -i "$APP_NAME" || echo "")
if [ -n "$IOREG_CMIO" ]; then
    check_status 0 "Extension found in IORegistry"
    echo "$IOREG_CMIO" | sed 's/^/    /'
else
    check_status 1 "Extension NOT found in IORegistry" "Extension may not be loading"
fi

# Check for CMIO processes
echo -e "\n  ${YELLOW}CMIO-related processes:${NC}"
ps aux | grep -E "cmio|appleh13camerad" | grep -v grep | head -5 || echo "    No CMIO processes found"

echo ""

# 6. Recent System Logs
echo -e "${BLUE}6. Recent System Logs Analysis${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check for extension loading attempts
echo -e "  ${YELLOW}Extension loading attempts (last 60s):${NC}"
log show --predicate "subsystem == 'com.apple.cmio' AND (eventMessage CONTAINS '$EXTENSION_NAME' OR eventMessage CONTAINS '$EXTENSION_ID')" --last 60s --style compact 2>/dev/null | tail -10 || echo "    No recent loading attempts found"

echo -e "\n  ${YELLOW}Sandbox violations (last 60s):${NC}"
log show --predicate "eventMessage CONTAINS 'sandbox' AND (eventMessage CONTAINS '$APP_NAME' OR eventMessage CONTAINS '$EXTENSION_NAME')" --last 60s --style compact 2>/dev/null | tail -10 || echo "    No sandbox violations found"

echo -e "\n  ${YELLOW}Permission/entitlement issues (last 60s):${NC}"
log show --predicate "(eventMessage CONTAINS 'entitlement' OR eventMessage CONTAINS 'authorization') AND (eventMessage CONTAINS '$APP_NAME' OR eventMessage CONTAINS '$EXTENSION_NAME')" --last 60s --style compact 2>/dev/null | tail -10 || echo "    No permission issues found"

echo -e "\n  ${YELLOW}CMIO errors (last 60s):${NC}"
log show --predicate "subsystem == 'com.apple.cmio' AND messageType == 'error'" --last 60s --style compact 2>/dev/null | tail -10 || echo "    No CMIO errors found"

echo ""

# 7. Entitlements Check
echo -e "${BLUE}7. Entitlements Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "  ${YELLOW}App Entitlements:${NC}"
codesign -d --entitlements - "$APP_PATH" 2>/dev/null | grep -E "camera|system-extension" | sed 's/^/    /' || echo "    No camera/extension entitlements found"

if [ -d "$EXTENSION_PATH" ]; then
    echo -e "\n  ${YELLOW}Extension Entitlements:${NC}"
    codesign -d --entitlements - "$EXTENSION_PATH" 2>/dev/null | grep -E "camera|cmio" | sed 's/^/    /' || echo "    No CMIO entitlements found"
fi

echo ""

# 8. Diagnostics Summary and Recommendations
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    Diagnostics Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}Potential Issues Found:${NC}"

# Check for common issues
ISSUES_FOUND=0

if [ ! -f "$EXTENSION_BINARY" ]; then
    echo -e "${RED}  • Extension binary not found${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ -z "$SYSEXT_STATUS" ]; then
    echo -e "${RED}  • Extension not registered with system${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ -z "$IOREG_CMIO" ]; then
    echo -e "${RED}  • Extension not discovered by CMIO subsystem${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}  No obvious issues detected${NC}"
fi

echo -e "\n${YELLOW}Recommended Actions:${NC}"
echo "  1. Ensure the app is properly built and installed"
echo "  2. Check Console.app for detailed error messages"
echo "  3. Try resetting system extensions: sudo systemextensionsctl reset"
echo "  4. Restart the camera daemon: sudo killall -9 appleh13camerad"
echo "  5. Ensure proper code signing with valid Developer ID"
echo "  6. Check that all required entitlements are present"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Diagnostics complete. Check Console.app for real-time logs.${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"