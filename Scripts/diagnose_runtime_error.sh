#!/bin/bash

# diagnose_runtime_error.sh - Find out why the app won't open
# Run this on the Mac where the app fails to open

echo "GigE Virtual Camera Runtime Diagnostics"
echo "======================================"
echo ""

APP_PATH="/Applications/GigEVirtualCamera.app"

# Basic checks
echo "1. System Information:"
sw_vers
echo "Processor: $(sysctl -n machdep.cpu.brand_string)"
echo ""

# Try to run the binary directly to see actual error
echo "2. Running app binary directly to see errors:"
echo "-------------------------------------------"
"$APP_PATH/Contents/MacOS/GigEVirtualCamera" 2>&1 | head -50
echo ""

# Check if all dylibs are present and loadable
echo "3. Checking bundled libraries:"
echo "------------------------------"
for lib in "$APP_PATH/Contents/Frameworks/"*.dylib; do
    if [ -f "$lib" ]; then
        echo "Checking: $(basename "$lib")"
        otool -L "$lib" | grep -E "not found|missing" || echo "  ✓ Dependencies look OK"
    fi
done
echo ""

# Check for missing system libraries
echo "4. System library dependencies:"
echo "-------------------------------"
otool -L "$APP_PATH/Contents/MacOS/GigEVirtualCamera" | grep -v "@" | grep -v "System/Library"
echo ""

# Console logs
echo "5. Recent console errors (last 2 minutes):"
echo "-----------------------------------------"
log show --predicate 'eventMessage contains "GigEVirtualCamera"' --last 2m --style syslog | tail -50
echo ""

echo "6. Crash reports:"
echo "-----------------"
ls -la ~/Library/Logs/DiagnosticReports/ | grep -i gige | tail -5 || echo "No recent crash reports found"
echo ""

echo "Diagnostics complete. Look for error messages above."