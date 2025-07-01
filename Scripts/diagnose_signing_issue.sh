#!/bin/bash

echo "=== GigE Virtual Camera Extension Signing Diagnostics ==="
echo

APP_PATH="/Applications/GigEVirtualCamera.app"
EXT_PATH="$APP_PATH/Contents/Library/SystemExtensions/GigECameraExtension.systemextension"

echo "1. Checking if app exists at required location..."
if [ -d "$APP_PATH" ]; then
    echo "✓ App found at $APP_PATH"
else
    echo "✗ App not found at $APP_PATH"
    echo "  System extensions MUST be run from /Applications"
    exit 1
fi

echo
echo "2. Checking app signature..."
if codesign -v "$APP_PATH" 2>&1 | grep -q "valid on disk"; then
    echo "✓ App is signed"
    codesign -dvv "$APP_PATH" 2>&1 | grep -E "Identifier=|Authority=|TeamIdentifier="
else
    echo "✗ App is NOT signed or signature is invalid"
    codesign -dvv "$APP_PATH" 2>&1
fi

echo
echo "3. Checking app entitlements..."
codesign -d --entitlements - "$APP_PATH" 2>&1 | grep -A 20 "<?xml" || echo "✗ No entitlements found"

echo
echo "4. Checking extension bundle..."
if [ -d "$EXT_PATH" ]; then
    echo "✓ Extension found at correct location"
    echo "  Bundle structure:"
    ls -la "$APP_PATH/Contents/Library/SystemExtensions/"
else
    echo "✗ Extension not found at $EXT_PATH"
fi

echo
echo "5. Checking extension signature..."
if [ -d "$EXT_PATH" ]; then
    if codesign -v "$EXT_PATH" 2>&1 | grep -q "valid on disk"; then
        echo "✓ Extension is signed"
        codesign -dvv "$EXT_PATH" 2>&1 | grep -E "Identifier=|Authority=|TeamIdentifier="
    else
        echo "✗ Extension is NOT signed or signature is invalid"
        codesign -dvv "$EXT_PATH" 2>&1
    fi
fi

echo
echo "6. Checking extension Info.plist..."
if [ -f "$EXT_PATH/Contents/Info.plist" ]; then
    echo "✓ Extension Info.plist found"
    plutil -p "$EXT_PATH/Contents/Info.plist" | grep -E "CFBundleIdentifier|CMIOExtension" -A 2
else
    echo "✗ Extension Info.plist not found"
fi

echo
echo "7. Checking system extension status..."
systemextensionsctl list

echo
echo "8. Checking for provisioning profiles..."
if [ -f "$APP_PATH/Contents/embedded.provisionprofile" ]; then
    echo "✓ App has embedded provisioning profile"
else
    echo "✗ No provisioning profile found (OK for Developer ID signed apps)"
fi

echo
echo "9. Checking development team..."
security find-identity -v -p codesigning | grep "S368GH6KF7" || echo "✗ No valid signing identity found for team S368GH6KF7"

echo
echo "=== Recommendations ==="
echo "1. Ensure the app is properly signed with a valid Developer ID or development certificate"
echo "2. Make sure you're running the app from /Applications"
echo "3. Check that both app and extension have matching team IDs"
echo "4. For development, use a development provisioning profile that includes the system extension entitlement"