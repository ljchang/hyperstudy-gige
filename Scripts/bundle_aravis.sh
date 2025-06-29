#!/bin/bash

# Bundle Aravis and dependencies with the app
# This script copies Aravis and its dependencies into the app bundle and updates library paths

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <app_bundle_path>"
    exit 1
fi

APP_BUNDLE="$1"
FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
# Extension doesn't need Aravis libraries anymore
# EXTENSION_PATH="$APP_BUNDLE/Contents/PlugIns/GigECameraExtension.appex"

# Create Frameworks directory (only for main app)
mkdir -p "$FRAMEWORKS_DIR"

# Function to copy library and its dependencies
copy_library_and_deps() {
    local lib_path="$1"
    local dest_dir="$2"
    local lib_name=$(basename "$lib_path")
    
    if [ ! -f "$lib_path" ]; then
        echo "Warning: Library not found: $lib_path"
        return
    fi
    
    # Skip if already copied
    if [ -f "$dest_dir/$lib_name" ]; then
        return
    fi
    
    echo "Copying $lib_name..."
    cp "$lib_path" "$dest_dir/"
    
    # Get dependencies
    local deps=$(otool -L "$lib_path" | grep -E "(opt/homebrew|usr/local)" | awk '{print $1}')
    
    for dep in $deps; do
        if [ -f "$dep" ]; then
            copy_library_and_deps "$dep" "$dest_dir"
        fi
    done
}

# Find Aravis and related libraries
ARAVIS_LIB=$(find /opt/homebrew/lib -name "libaravis-0.8*.dylib" | head -1)
GLIB_LIB=$(find /opt/homebrew/lib -name "libglib-2.0*.dylib" | head -1)
GOBJECT_LIB=$(find /opt/homebrew/lib -name "libgobject-2.0*.dylib" | head -1)
GIO_LIB=$(find /opt/homebrew/lib -name "libgio-2.0*.dylib" | head -1)

# Copy libraries to app only (extension doesn't need them)
for lib in "$ARAVIS_LIB" "$GLIB_LIB" "$GOBJECT_LIB" "$GIO_LIB"; do
    copy_library_and_deps "$lib" "$FRAMEWORKS_DIR"
done

# Update library paths in the app binary
APP_BINARY="$APP_BUNDLE/Contents/MacOS/GigEVirtualCamera"

echo "Updating library paths..."

# Function to update library paths
update_library_paths() {
    local binary="$1"
    local frameworks_rel_path="$2"
    
    # Get all libraries in Frameworks
    for lib in "$FRAMEWORKS_DIR"/*.dylib; do
        if [ -f "$lib" ]; then
            local lib_name=$(basename "$lib")
            local old_path=$(otool -L "$binary" 2>/dev/null | grep "$lib_name" | awk '{print $1}' | head -1)
            
            if [ -n "$old_path" ]; then
                echo "Updating $lib_name in $(basename $binary)"
                install_name_tool -change "$old_path" "@loader_path/$frameworks_rel_path/$lib_name" "$binary"
            fi
        fi
    done
}

# Update paths in all libraries
for lib in "$FRAMEWORKS_DIR"/*.dylib; do
    if [ -f "$lib" ]; then
        update_library_paths "$lib" "../Frameworks"
    fi
done

# Extension no longer needs Aravis libraries

# Update paths in app debug dylib
APP_DEBUG_DYLIB="$APP_BUNDLE/Contents/MacOS/GigEVirtualCamera.debug.dylib"

if [ -f "$APP_DEBUG_DYLIB" ]; then
    echo "Updating paths in app debug dylib..."
    update_library_paths "$APP_DEBUG_DYLIB" "../Frameworks"
fi

update_library_paths "$APP_BINARY" "../Frameworks"

echo "Library bundling complete!"

# Verify
echo -e "\nVerifying library paths in app:"
otool -L "$APP_BINARY" | grep -E "(aravis|glib|gio|gobject)" || echo "No Aravis libraries linked"

echo -e "\nLibraries in app Frameworks:"
ls -la "$FRAMEWORKS_DIR"/*.dylib 2>/dev/null || echo "No libraries found"