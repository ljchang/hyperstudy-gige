#!/bin/bash

echo "Testing CMIO Extension Loading..."
echo "================================="

# 1. Kill the app to start fresh
echo "1. Stopping app..."
killall GigEVirtualCamera 2>/dev/null
sleep 2

# 2. Check if any crash reports exist
echo -e "\n2. Checking for crash reports..."
CRASH_COUNT=$(find ~/Library/Logs/DiagnosticReports -name "*GigE*" -mtime -1 2>/dev/null | wc -l)
if [ "$CRASH_COUNT" -gt 0 ]; then
    echo "Found $CRASH_COUNT recent crash reports:"
    find ~/Library/Logs/DiagnosticReports -name "*GigE*" -mtime -1 -exec basename {} \; | head -5
else
    echo "No recent crash reports found"
fi

# 3. Start Console logging in background
echo -e "\n3. Starting log capture..."
LOG_FILE="/tmp/gige_camera_log.txt"
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.apple.cmio"' > "$LOG_FILE" 2>&1 &
LOG_PID=$!
echo "Log capture started (PID: $LOG_PID)"

# 4. Launch the app
echo -e "\n4. Launching app..."
open /Applications/GigEVirtualCamera.app

# Wait for app to start
sleep 3

# 5. Check processes again
echo -e "\n5. Checking processes..."
echo "App process:"
ps aux | grep -v grep | grep "GigEVirtualCamera.app" || echo "Not found"
echo -e "\nExtension process:"
ps aux | grep -v grep | grep "GigECameraExtension" || echo "Not found"

# 6. Try to trigger camera enumeration
echo -e "\n6. Triggering camera enumeration..."
osascript -e 'tell application "QuickTime Player" to quit' 2>/dev/null
sleep 1
osascript -e 'tell application "QuickTime Player" to activate' 2>/dev/null
sleep 2

# 7. Stop log capture and show results
echo -e "\n7. Log results..."
kill $LOG_PID 2>/dev/null
sleep 1

echo "Recent log entries:"
grep -E "(error|fail|denied|crash|GigE)" "$LOG_FILE" | tail -20

# 8. Manual test suggestion
echo -e "\n8. Manual test:"
echo "Please open QuickTime Player manually and:"
echo "1. Go to File > New Movie Recording"
echo "2. Click the dropdown arrow next to the record button"
echo "3. Check if 'GigE Virtual Camera' appears in the list"
echo ""
echo "Also check Console.app:"
echo "1. Open Console.app"
echo "2. In the search field, type: com.lukechang.GigEVirtualCamera"
echo "3. Click 'Start' to begin streaming logs"
echo "4. Try launching the app again"

# Cleanup
rm -f "$LOG_FILE"