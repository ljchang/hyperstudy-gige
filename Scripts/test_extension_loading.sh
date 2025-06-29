#!/bin/bash

echo "Testing Extension Loading Issue"
echo "==============================="

# Check if the extension can be loaded
echo "1. Testing extension binary directly..."
EXTENSION_PATH="/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex/Contents/MacOS/GigECameraExtension"

echo "Checking if extension binary exists:"
if [ -f "$EXTENSION_PATH" ]; then
    echo "✓ Extension binary exists"
else
    echo "✗ Extension binary not found"
    exit 1
fi

echo -e "\n2. Checking for missing libraries..."
MISSING_LIBS=$(otool -L "$EXTENSION_PATH" | grep "/opt/homebrew" | wc -l)
echo "Found $MISSING_LIBS libraries linked to /opt/homebrew"

echo -e "\n3. Testing if extension can be loaded..."
# Try to load the extension binary
if dyld_info -platform "$EXTENSION_PATH" >/dev/null 2>&1; then
    echo "✓ Extension binary structure is valid"
else
    echo "✗ Extension binary has loading issues"
fi

echo -e "\n4. Checking library dependencies:"
otool -L "$EXTENSION_PATH" | grep -E "(aravis|glib|gio|gobject)" | while read -r line; do
    LIB_PATH=$(echo "$line" | awk '{print $1}')
    if [ -f "$LIB_PATH" ]; then
        echo "✓ Found: $LIB_PATH"
    else
        echo "✗ Missing: $LIB_PATH"
    fi
done

echo -e "\n5. Checking if app bundle contains required libraries..."
FRAMEWORKS_DIR="/Applications/GigEVirtualCamera.app/Contents/Frameworks"
if [ -d "$FRAMEWORKS_DIR" ]; then
    echo "Frameworks directory contents:"
    ls -la "$FRAMEWORKS_DIR" | grep -E "(aravis|glib|gio|gobject)"
else
    echo "✗ No Frameworks directory found"
fi

echo -e "\n6. DIAGNOSIS:"
echo "The extension is linking to libraries in /opt/homebrew which:"
echo "1. Don't exist on most users' machines"
echo "2. Can't be accessed from a sandboxed extension"
echo ""
echo "SOLUTION: The extension should NOT link to Aravis or glib libraries."
echo "Only the main app should use Aravis. The extension should only:"
echo "- Receive frames from the main app"
echo "- Provide them to the CMIO system"
echo ""
echo "The extension build settings need to be updated to exclude Aravis/glib dependencies."