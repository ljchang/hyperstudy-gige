#!/bin/bash

# Sign frameworks after build
# This ensures all dynamically loaded libraries are properly signed

set -e

APP_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
FRAMEWORKS_PATH="${APP_PATH}/Contents/Frameworks"

if [ -d "${FRAMEWORKS_PATH}" ]; then
    echo "Signing frameworks in ${FRAMEWORKS_PATH}..."
    
    # Find all .dylib files and sign them
    find "${FRAMEWORKS_PATH}" -name "*.dylib" -type f | while read -r dylib; do
        echo "Signing: ${dylib}"
        codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements,flags --timestamp "${dylib}"
    done
    
    # Sign the app bundle (excluding the already-signed extension)
    echo "Re-signing app bundle..."
    codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --entitlements "${CODE_SIGN_ENTITLEMENTS}" --timestamp "${APP_PATH}"
    
    echo "Framework signing complete"
else
    echo "No frameworks directory found"
fi