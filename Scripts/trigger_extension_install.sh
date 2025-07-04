#!/bin/bash

echo "Triggering extension installation..."

# Send a notification to the app to install the extension
osascript <<EOF
tell application "System Events"
    tell process "GigEVirtualCamera"
        set frontmost to true
        delay 0.5
        
        # Try to click the "Install Extension" button
        try
            click button "Install Extension" of window 1
            delay 1
            return "Clicked Install Extension button"
        on error
            # If that doesn't work, try uninstall first
            try
                click button "Uninstall Extension" of window 1
                delay 2
                click button "Install Extension" of window 1
                return "Clicked Uninstall then Install"
            on error
                return "Could not find Install/Uninstall buttons"
            end try
        end try
    end tell
end tell
EOF

echo "Waiting for installation..."
sleep 5

# Check if extension is now installed
systemextensionsctl list | grep -A1 "GigE"