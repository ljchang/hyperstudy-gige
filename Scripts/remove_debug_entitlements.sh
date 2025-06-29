#!/bin/bash

# Script to remove debug entitlements from signed app
# This is needed for CMIOExtensions to load properly

APP_PATH="/Applications/GigEVirtualCamera.app"
EXTENSION_PATH="$APP_PATH/Contents/Library/SystemExtensions/GigECameraExtension.systemextension"

echo "Removing debug entitlements from GigE Virtual Camera..."

# Extract current entitlements
codesign -d --entitlements :- "$APP_PATH" > /tmp/app_entitlements.plist 2>/dev/null
codesign -d --entitlements :- "$EXTENSION_PATH" > /tmp/ext_entitlements.plist 2>/dev/null

# Remove get-task-allow entitlement
/usr/libexec/PlistBuddy -c "Delete :com.apple.security.get-task-allow" /tmp/app_entitlements.plist 2>/dev/null
/usr/libexec/PlistBuddy -c "Delete :com.apple.security.get-task-allow" /tmp/ext_entitlements.plist 2>/dev/null

# Re-sign with cleaned entitlements
echo "Re-signing app..."
codesign --force --deep --sign - --entitlements /tmp/app_entitlements.plist "$APP_PATH"

echo "Re-signing extension..."
codesign --force --sign - --entitlements /tmp/ext_entitlements.plist "$EXTENSION_PATH"

# Clean up
rm /tmp/app_entitlements.plist /tmp/ext_entitlements.plist

echo "Done! Please restart the app."