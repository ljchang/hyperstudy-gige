#!/bin/bash

echo "=== Testing Sink Stream Connection ==="
echo ""

# Check if both processes are running
echo "1. Checking processes:"
ps aux | grep -E "(GigEVirtualCamera|Photo Booth)" | grep -v grep | awk '{print "   " $11}'

echo ""
echo "2. Checking for Test XPC Connection button in app..."

# Try to click the Test XPC Connection button using AppleScript
osascript <<EOF
tell application "GigEVirtualCamera"
    activate
end tell

delay 1

tell application "System Events"
    tell process "GigEVirtualCamera"
        set frontmost to true
        
        -- Try to find and click the button
        try
            -- Look for the Test XPC Connection button
            click button "Test XPC Connection" of window 1
            return "Successfully clicked Test XPC Connection button"
        on error errMsg
            -- If not found, try looking in groups
            try
                set allButtons to every button of every group of window 1
                repeat with aButton in allButtons
                    if name of aButton contains "Test" or name of aButton contains "XPC" then
                        click aButton
                        return "Found and clicked XPC test button"
                    end if
                end repeat
            on error
                return "Could not find Test XPC Connection button. Error: " & errMsg
            end try
        end try
    end tell
end tell
EOF

echo ""
echo "3. Waiting for connection to establish..."
sleep 3

echo ""
echo "4. Checking recent logs for connection status:"
log show --predicate 'process == "GigEVirtualCamera" AND (message CONTAINS "sink" OR message CONTAINS "queue" OR message CONTAINS "connected")' --last 10s 2>/dev/null | grep -E "(Successfully|Failed|connected|queue)" | tail -10