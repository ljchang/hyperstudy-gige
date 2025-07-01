#!/bin/bash

# Trigger the app to connect to the sink stream and send test frames

echo "Triggering sink stream connection..."

# Use AppleScript to click the test button in the app UI
osascript <<EOF
tell application "GigEVirtualCamera"
    activate
end tell

-- Give it a moment to come to front
delay 0.5

tell application "System Events"
    tell process "GigEVirtualCamera"
        -- Look for the "Test Connection" button and click it
        try
            click button "Test Connection" of window 1
            delay 1
            return "Clicked Test Connection button"
        on error
            return "Could not find Test Connection button"
        end try
    end tell
end tell
EOF

echo "Checking logs for frame delivery..."
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "FrameSender"' --last 10s --style compact | tail -20