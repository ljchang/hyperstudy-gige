#!/bin/bash

# sign_bundled_libraries.sh - Sign all bundled libraries with proper identity
# This script runs after bundle_aravis.sh to ensure libraries are properly signed

set -e

APP_BUNDLE="${1:-${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app}"
FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"

echo "Signing bundled libraries..."

# Only sign if we have a valid code signing identity
if [ -z "${EXPANDED_CODE_SIGN_IDENTITY}" ]; then
    echo "No code signing identity found, skipping library signing"
    exit 0
fi

# Sign each library in the Frameworks directory
if [ -d "$FRAMEWORKS_DIR" ]; then
    for lib in "$FRAMEWORKS_DIR"/*.dylib; do
        if [ -f "$lib" ]; then
            lib_name=$(basename "$lib")
            echo "  Signing: $lib_name"
            
            if [ "${CONFIGURATION}" = "Release" ]; then
                # Release build - use Developer ID with hardened runtime and timestamp
                codesign --force \
                    --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
                    --timestamp \
                    --options runtime \
                    --entitlements - \
                    "$lib" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
EOF
            else
                # Debug build - simple signing
                codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" "$lib"
            fi
        fi
    done
    echo "✅ All libraries signed successfully"
else
    echo "No Frameworks directory found"
fi

# Verify signatures
echo ""
echo "Verifying library signatures:"
for lib in "$FRAMEWORKS_DIR"/*.dylib; do
    if [ -f "$lib" ]; then
        lib_name=$(basename "$lib")
        if codesign -dv "$lib" 2>&1 | grep -q "Signature="; then
            echo "  ✓ $lib_name: signed"
        else
            echo "  ✗ $lib_name: NOT SIGNED"
            exit 1
        fi
    fi
done

echo ""
echo "Library signing complete!"