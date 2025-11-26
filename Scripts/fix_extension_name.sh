#!/bin/bash

# Fix the extension folder name to match its bundle identifier
# macOS requires the folder name to match the bundle ID

echo "=== Fixing Extension Folder Name ==="

APP_PATH="/Applications/GigEVirtualCamera.app"
OLD_EXT_PATH="$APP_PATH/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
NEW_EXT_PATH="$APP_PATH/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"

if [ -d "$OLD_EXT_PATH" ]; then
    echo "Found extension at: $OLD_EXT_PATH"
    echo "Renaming to match bundle ID..."
    
    # Remove any existing one with the new name
    rm -rf "$NEW_EXT_PATH" 2>/dev/null || true
    
    # Rename the extension
    mv "$OLD_EXT_PATH" "$NEW_EXT_PATH"
    
    echo "Extension renamed to: com.lukechang.GigEVirtualCamera.Extension.systemextension"
    
    # Re-sign after renaming
    IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | awk '{print $2}')
    if [ -n "$IDENTITY" ]; then
        echo "Re-signing extension..."
        codesign --force --deep --sign "$IDENTITY" --timestamp=none "$NEW_EXT_PATH"
        
        echo "Re-signing app..."
        codesign --force --deep --sign "$IDENTITY" \
            --entitlements /Users/lukechang/Github/hyperstudy-gige/GigECameraApp/GigECamera-Debug.entitlements \
            --options runtime \
            --timestamp=none \
            "$APP_PATH"
    fi
    
    echo "✅ Done!"
else
    echo "Extension not found at expected location: $OLD_EXT_PATH"
    
    # Check if it's already renamed
    if [ -d "$NEW_EXT_PATH" ]; then
        echo "Extension already has correct name!"
    else
        echo "No extension found in app bundle!"
    fi
fi