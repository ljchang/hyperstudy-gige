#!/bin/bash

# Clean up incorrectly generated .appex file
# This is a workaround for Xcode creating both .appex and .systemextension

set -e

APP_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
APPEX_PATH="${APP_PATH}/Contents/PlugIns/GigECameraExtension.appex"

if [ -d "${APPEX_PATH}" ]; then
    echo "Removing incorrectly generated .appex file..."
    rm -rf "${APPEX_PATH}"
    
    # Remove PlugIns directory if empty
    rmdir "${APP_PATH}/Contents/PlugIns" 2>/dev/null || true
    
    echo "Cleanup complete"
fi