#!/bin/bash

# Script to fix code signing for local testing

set -e

APP_PATH="${1:-/Applications/GigEVirtualCamera.app}"

echo "=== Fixing code signing for: $APP_PATH ==="

# Remove any existing signatures
echo "Removing existing signatures..."
find "$APP_PATH" -type f -name "*.dylib" -exec codesign --remove-signature {} \; 2>/dev/null || true
codesign --remove-signature "$APP_PATH/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension" 2>/dev/null || true
codesign --remove-signature "$APP_PATH" 2>/dev/null || true

# Get the development identity
IDENTITY=$(security find-identity -v -p codesigning | grep -E "Apple Development|Mac Developer" | head -1 | awk '{print $2}')
if [ -z "$IDENTITY" ]; then
    echo "Error: No development certificate found"
    echo "Please install a development certificate in Keychain"
    exit 1
fi

echo "Using identity: $IDENTITY"

# Sign embedded libraries first
if [ -d "$APP_PATH/Contents/Frameworks" ]; then
    echo "Signing embedded libraries..."
    find "$APP_PATH/Contents/Frameworks" -name "*.dylib" | while read lib; do
        echo "  - $(basename "$lib")"
        codesign --force --sign "$IDENTITY" "$lib"
    done
fi

# Sign the system extension
EXTENSION_PATH="$APP_PATH/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
if [ -d "$EXTENSION_PATH" ]; then
    echo "Signing system extension..."
    # Create a minimal entitlements file for the extension if needed
    EXTENSION_ENTITLEMENTS="/tmp/extension_entitlements.plist"
    cat > "$EXTENSION_ENTITLEMENTS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.lukechang.gigecamera</string>
    </array>
</dict>
</plist>
EOF
    
    codesign --force --sign "$IDENTITY" \
        --entitlements "$EXTENSION_ENTITLEMENTS" \
        --options runtime \
        --timestamp=none \
        "$EXTENSION_PATH"
    
    rm -f "$EXTENSION_ENTITLEMENTS"
fi

# Sign the main app
echo "Signing main app..."
# Create entitlements for the main app
MAIN_ENTITLEMENTS="/tmp/main_entitlements.plist"
cat > "$MAIN_ENTITLEMENTS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.lukechang.gigecamera</string>
    </array>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.developer.system-extension.install</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign "$IDENTITY" \
    --entitlements "$MAIN_ENTITLEMENTS" \
    --options runtime \
    --timestamp=none \
    "$APP_PATH"

rm -f "$MAIN_ENTITLEMENTS"

# Verify
echo ""
echo "Verifying code signature..."
codesign -vvv --deep --strict "$APP_PATH" 2>&1 | grep -E "valid|satisfied" || true

echo ""
echo "=== Code signing complete ==="
echo "You can now run: open $APP_PATH"