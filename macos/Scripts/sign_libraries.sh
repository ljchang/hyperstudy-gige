#!/bin/bash
# Sign bundled libraries

set -e

FRAMEWORKS_DIR="$1"
IDENTITY="${CODE_SIGN_IDENTITY:-Apple Development}"

if [ -z "$FRAMEWORKS_DIR" ]; then
    echo "Usage: $0 <frameworks_directory>"
    exit 1
fi

# Find the certificate SHA to avoid ambiguity
# First try to find the exact match, then use the first one
# The SHA is the second field (after the number and parenthesis)
CERT_LINE=$(security find-identity -p codesigning -v | grep "$IDENTITY" | head -1)
CERT_SHA=$(echo "$CERT_LINE" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+([A-F0-9]+)[[:space:]]+.*/\1/')

if [ -z "$CERT_SHA" ]; then
    echo "Warning: Could not find certificate for identity: $IDENTITY"
    echo "Available certificates:"
    security find-identity -p codesigning -v
    exit 1
fi

echo "Signing libraries with certificate: $CERT_SHA ($IDENTITY)"

cd "$FRAMEWORKS_DIR"

# Sign each library
for lib in *.dylib; do
    if [ -f "$lib" ]; then
        echo "Signing $lib..."
        codesign --force --sign "$CERT_SHA" --timestamp "$lib"
    fi
done

echo "Library signing complete!"