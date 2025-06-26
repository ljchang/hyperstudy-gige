#!/bin/bash

echo "Testing Aravis integration..."

# Find the built app
APP_PATH="/Users/lukechang/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-fzpkfzdcwiqsltcxdzwaqvfktasi/Build/Products/Debug/GigEVirtualCamera.app"

if [ ! -d "$APP_PATH" ]; then
    echo "App not found at $APP_PATH"
    exit 1
fi

echo -e "\n1. Checking bundled libraries:"
ls -la "$APP_PATH/Contents/Frameworks/" | grep -E "(aravis|glib)"

echo -e "\n2. Checking extension binary dependencies:"
otool -L "$APP_PATH/Contents/PlugIns/GigECameraExtension.appex/Contents/MacOS/GigECameraExtension"

echo -e "\n3. Checking if Aravis symbols are undefined:"
nm -u "$APP_PATH/Contents/PlugIns/GigECameraExtension.appex/Contents/MacOS/GigECameraExtension" 2>/dev/null | grep -E "arv_" | head -10

echo -e "\n4. Running the app and checking logs:"
echo "Opening the app..."
open "$APP_PATH"

sleep 2

echo -e "\n5. Checking system logs for our extension:"
log show --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --last 30s --info --debug 2>/dev/null | tail -20

echo -e "\n6. Checking for camera extension registration:"
pluginkit -mA -i com.apple.cmio | grep -i gige || echo "No GigE camera extension found"