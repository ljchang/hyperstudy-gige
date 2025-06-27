#!/bin/bash

# Fix library linking for Aravis in the built app
# This is a temporary workaround until we fix the build configuration

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <app_bundle_path>"
    exit 1
fi

APP_BUNDLE="$1"
EXTENSION_BINARY="$APP_BUNDLE/Contents/PlugIns/GigECameraExtension.appex/Contents/MacOS/GigECameraExtension"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/GigEVirtualCamera"

echo "Fixing library linking..."

# Add library dependencies to the extension
install_name_tool -add_rpath "@loader_path/../Frameworks" "$EXTENSION_BINARY" 2>/dev/null || true
install_name_tool -add_rpath "@loader_path/../../../../Frameworks" "$EXTENSION_BINARY" 2>/dev/null || true

# Link the required libraries
for lib in libaravis-0.8 libgio-2.0 libgobject-2.0 libglib-2.0; do
    # Try to find the library
    LIB_PATH=$(find /opt/homebrew/lib -name "${lib}*.dylib" | head -1)
    if [ -n "$LIB_PATH" ]; then
        echo "Linking $lib..."
        # Get the actual library name
        LIB_NAME=$(basename "$LIB_PATH")
        # Add the library dependency
        install_name_tool -change "$LIB_PATH" "@loader_path/../Frameworks/$LIB_NAME" "$EXTENSION_BINARY" 2>/dev/null || \
        install_name_tool -add_dylib "@loader_path/../Frameworks/$LIB_NAME" "$EXTENSION_BINARY" 2>/dev/null || true
    fi
done

# Do the same for the main app
install_name_tool -add_rpath "@loader_path/../Frameworks" "$APP_BINARY" 2>/dev/null || true

for lib in libaravis-0.8 libgio-2.0 libgobject-2.0 libglib-2.0; do
    LIB_PATH=$(find /opt/homebrew/lib -name "${lib}*.dylib" | head -1)
    if [ -n "$LIB_PATH" ]; then
        LIB_NAME=$(basename "$LIB_PATH")
        install_name_tool -change "$LIB_PATH" "@loader_path/../Frameworks/$LIB_NAME" "$APP_BINARY" 2>/dev/null || \
        install_name_tool -add_dylib "@loader_path/../Frameworks/$LIB_NAME" "$APP_BINARY" 2>/dev/null || true
    fi
done

echo "Verifying..."
echo -e "\nExtension libraries:"
otool -L "$EXTENSION_BINARY" | grep -E "(aravis|glib|gio|gobject)" || echo "No Aravis libraries linked"

echo -e "\nApp libraries:"
otool -L "$APP_BINARY" | grep -E "(aravis|glib|gio|gobject)" || echo "No Aravis libraries linked"