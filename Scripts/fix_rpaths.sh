#!/bin/bash

# Fix rpath and library paths for bundled Aravis libraries
# This makes the app fully self-contained

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <app_bundle_path>"
    exit 1
fi

APP_BUNDLE="$1"
FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
EXTENSION_PATH="$APP_BUNDLE/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
EXTENSION_FRAMEWORKS_DIR="$EXTENSION_PATH/Contents/Frameworks"

echo "Fixing rpaths and library paths..."

# Function to fix library install names and dependencies
fix_library_paths() {
    local lib_path="$1"
    local frameworks_dir="$2"
    local lib_name=$(basename "$lib_path")
    
    echo "Processing $lib_name..."
    
    # Change the library's install name to use @rpath
    install_name_tool -id "@rpath/$lib_name" "$lib_path" 2>/dev/null || true
    
    # Update all dependencies to use @rpath
    local deps=$(otool -L "$lib_path" | grep -E "/opt/homebrew|/usr/local" | awk '{print $1}')
    
    for dep in $deps; do
        dep_name=$(basename "$dep")
        if [ -f "$frameworks_dir/$dep_name" ]; then
            echo "  Updating dependency: $dep_name"
            install_name_tool -change "$dep" "@rpath/$dep_name" "$lib_path" 2>/dev/null || true
        fi
    done
}

# Function to add rpaths to binary
add_rpaths() {
    local binary="$1"
    shift
    local rpaths=("$@")
    
    for rpath in "${rpaths[@]}"; do
        # Check if rpath already exists
        if ! otool -l "$binary" 2>/dev/null | grep -A2 LC_RPATH | grep -q "$rpath"; then
            echo "Adding rpath $rpath to $(basename $binary)"
            install_name_tool -add_rpath "$rpath" "$binary" 2>/dev/null || true
        fi
    done
}

# Fix all libraries in Frameworks directories
echo -e "\nFixing libraries in app Frameworks..."
for lib in "$FRAMEWORKS_DIR"/*.dylib; do
    if [ -f "$lib" ]; then
        fix_library_paths "$lib" "$FRAMEWORKS_DIR"
    fi
done

echo -e "\nFixing libraries in extension Frameworks..."
for lib in "$EXTENSION_FRAMEWORKS_DIR"/*.dylib; do
    if [ -f "$lib" ]; then
        fix_library_paths "$lib" "$EXTENSION_FRAMEWORKS_DIR"
    fi
done

# Update binaries to use @rpath
EXTENSION_BINARY="$EXTENSION_PATH/Contents/MacOS/GigECameraExtension"
EXTENSION_DEBUG_DYLIB="$EXTENSION_PATH/Contents/MacOS/GigECameraExtension.debug.dylib"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/GigEVirtualCamera"
APP_DEBUG_DYLIB="$APP_BUNDLE/Contents/MacOS/GigEVirtualCamera.debug.dylib"

# Add rpaths to binaries
echo -e "\nAdding rpaths to binaries..."
add_rpaths "$EXTENSION_BINARY" "@loader_path/../Frameworks" "@loader_path/../../../../Frameworks"
add_rpaths "$APP_BINARY" "@loader_path/../Frameworks"

if [ -f "$EXTENSION_DEBUG_DYLIB" ]; then
    echo -e "\nFixing extension debug dylib..."
    add_rpaths "$EXTENSION_DEBUG_DYLIB" "@loader_path/../Frameworks" "@loader_path/../../../../Frameworks"
    
    # Update Aravis references in debug dylib
    aravis_deps=$(otool -L "$EXTENSION_DEBUG_DYLIB" | grep -E "/opt/homebrew.*aravis|/opt/homebrew.*glib|/opt/homebrew.*gio|/opt/homebrew.*gobject" | awk '{print $1}')
    
    for dep in $aravis_deps; do
        dep_name=$(basename "$dep")
        echo "  Updating $dep_name reference"
        install_name_tool -change "$dep" "@rpath/$dep_name" "$EXTENSION_DEBUG_DYLIB" 2>/dev/null || true
    done
fi

if [ -f "$APP_DEBUG_DYLIB" ]; then
    echo -e "\nFixing app debug dylib..."
    add_rpaths "$APP_DEBUG_DYLIB" "@loader_path/../Frameworks"
    
    # Update Aravis references in debug dylib
    aravis_deps=$(otool -L "$APP_DEBUG_DYLIB" | grep -E "/opt/homebrew.*aravis|/opt/homebrew.*glib|/opt/homebrew.*gio|/opt/homebrew.*gobject" | awk '{print $1}')
    
    for dep in $aravis_deps; do
        dep_name=$(basename "$dep")
        echo "  Updating $dep_name reference"
        install_name_tool -change "$dep" "@rpath/$dep_name" "$APP_DEBUG_DYLIB" 2>/dev/null || true
    done
fi

echo -e "\nVerifying library paths..."

# Verify debug dylib
if [ -f "$EXTENSION_DEBUG_DYLIB" ]; then
    echo -e "\nExtension debug dylib dependencies:"
    otool -L "$EXTENSION_DEBUG_DYLIB" | grep -E "(aravis|glib|gio|gobject|@rpath)" || echo "No matching libraries"
fi

# Verify one of the bundled libraries
if [ -f "$FRAMEWORKS_DIR/libaravis-0.8.0.dylib" ]; then
    echo -e "\nAravis library dependencies:"
    otool -L "$FRAMEWORKS_DIR/libaravis-0.8.0.dylib" | grep -E "(glib|gio|gobject|@rpath)" | head -10
fi

echo -e "\nLibrary path fixing complete!"