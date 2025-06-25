#!/bin/bash
# Bundle Aravis and dependencies into the app

set -e

echo "Bundling Aravis libraries..."

# Get the framework destination
FRAMEWORKS_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "$FRAMEWORKS_DIR"

# List of libraries to bundle
LIBS=(
    "libaravis-0.8.dylib"
    "libgio-2.0.0.dylib"
    "libgobject-2.0.0.dylib"
    "libglib-2.0.0.dylib"
    "libgmodule-2.0.0.dylib"
    "libintl.8.dylib"
    "libpcre2-8.0.dylib"
    "libffi.8.dylib"
)

# Copy each library
for lib in "${LIBS[@]}"; do
    if [ -f "/opt/homebrew/lib/$lib" ]; then
        echo "Copying $lib..."
        cp "/opt/homebrew/lib/$lib" "$FRAMEWORKS_DIR/" || true
    else
        echo "Warning: $lib not found"
    fi
done

# Fix library paths
echo "Fixing library paths..."
"${SRCROOT}/Scripts/fix_library_paths.sh" "$FRAMEWORKS_DIR"

# Sign libraries
echo "Signing libraries..."
"${SRCROOT}/Scripts/sign_libraries.sh" "$FRAMEWORKS_DIR"

echo "Bundling complete!"