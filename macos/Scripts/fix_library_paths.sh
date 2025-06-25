#!/bin/bash
# Fix library paths to use @rpath

set -e

FRAMEWORKS_DIR="$1"

if [ -z "$FRAMEWORKS_DIR" ]; then
    echo "Usage: $0 <frameworks_directory>"
    exit 1
fi

cd "$FRAMEWORKS_DIR"

# Function to fix dependencies for a library
fix_deps() {
    local lib="$1"
    echo "Fixing $lib..."
    
    # Change the library ID
    install_name_tool -id "@rpath/$(basename "$lib")" "$lib"
    
    # Get all dependencies
    deps=$(otool -L "$lib" | grep -E "(homebrew|local)" | awk '{print $1}')
    
    # Fix each dependency
    for dep in $deps; do
        local dep_name=$(basename "$dep")
        if [ -f "$dep_name" ]; then
            install_name_tool -change "$dep" "@rpath/$dep_name" "$lib"
        fi
    done
}

# Fix all dylib files
for lib in *.dylib; do
    if [ -f "$lib" ]; then
        fix_deps "$lib"
    fi
done

echo "Library paths fixed!"