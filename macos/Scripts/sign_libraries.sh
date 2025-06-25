#!/bin/bash
# Sign bundled libraries

set -e

FRAMEWORKS_DIR="$1"
IDENTITY="${CODE_SIGN_IDENTITY:-Apple Development}"

if [ -z "$FRAMEWORKS_DIR" ]; then
    echo "Usage: $0 <frameworks_directory>"
    exit 1
fi

echo "Signing libraries with identity: $IDENTITY"

cd "$FRAMEWORKS_DIR"

# Sign each library
for lib in *.dylib; do
    if [ -f "$lib" ]; then
        echo "Signing $lib..."
        codesign --force --sign "$IDENTITY" --timestamp "$lib"
    fi
done

echo "Library signing complete!"