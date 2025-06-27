#!/bin/bash

# Script to help test the GigE Virtual Camera app

echo "GigE Virtual Camera Test Helper"
echo "==============================="
echo ""

# Check if app exists
APP_PATH="/Users/lukechang/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-fzpkfzdcwiqsltcxdzwaqvfktasi/Build/Products/Debug/GigEVirtualCamera.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at: $APP_PATH"
    echo "Please build the app in Xcode first."
    exit 1
fi

echo "✅ App found at: $APP_PATH"
echo ""

# Option 1: Copy to Desktop for testing
echo "Option 1: Copy to Desktop for testing"
echo "This sometimes helps with system extension installation"
echo ""
echo "cp -R \"$APP_PATH\" ~/Desktop/"
echo ""

# Option 2: Create a signed package
echo "Option 2: For proper testing, you need to:"
echo "1. In Xcode: Product → Archive"
echo "2. In Organizer: Distribute App → Development → Export"
echo "3. Move exported app to /Applications"
echo "4. Run from /Applications"
echo ""

# Option 3: Check system extension status
echo "Current system extensions:"
systemextensionsctl list

echo ""
echo "To reset all system extensions (requires SIP disabled):"
echo "systemextensionsctl reset"
echo ""

echo "To view extension logs:"
echo "log stream --predicate 'subsystem == \"com.lukechang.GigEVirtualCamera.Extension\"'"