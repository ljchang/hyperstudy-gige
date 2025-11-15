#!/bin/bash

# resign_for_distribution.sh - Re-sign the installed app with proper entitlements for distribution
# This fixes validation errors by ensuring proper entitlements and removing provisioning profiles

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_PATH="/Applications/GigEVirtualCamera.app"
TEMP_DIR="$PROJECT_ROOT/build/temp_resign"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

echo ""
echo "🔧 Re-signing GigE Virtual Camera for Distribution"
echo "================================================"
echo ""

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    print_error "App not found at $APP_PATH"
    print_error "Please build and install the app first"
    exit 1
fi

# Create temp directory
print_status "Creating temporary working directory..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy app to temp location
print_status "Copying app for re-signing..."
cp -R "$APP_PATH" "$TEMP_DIR/GigEVirtualCamera.app"
WORK_APP="$TEMP_DIR/GigEVirtualCamera.app"
print_success "Working copy created"

# Step 1: Remove all provisioning profiles
print_status "Step 1: Removing embedded provisioning profiles..."
find "$WORK_APP" -name "*.provisionprofile" -o -name "embedded.provisionprofile" | while read profile; do
    rm -f "$profile"
    print_success "Removed: $(basename "$profile")"
done

# Step 2: Sign Aravis libraries
print_status "Step 2: Signing Aravis libraries..."
ARAVIS_DIR="$WORK_APP/Contents/Frameworks"
if [ -d "$ARAVIS_DIR" ]; then
    find "$ARAVIS_DIR" -name "*.dylib" | while read lib; do
        codesign --force --sign "Developer ID Application" \
            --options runtime \
            --timestamp \
            "$lib"
    done
    print_success "Aravis libraries signed"
fi

# Step 3: Sign the extension with proper entitlements
print_status "Step 3: Signing system extension with entitlements..."
EXTENSION_PATH="$WORK_APP/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
EXTENSION_ENTITLEMENTS="$PROJECT_ROOT/GigEVirtualCameraExtension/GigEVirtualCameraExtension-Distribution.entitlements"

if [ -d "$EXTENSION_PATH" ]; then
    if [ -f "$EXTENSION_ENTITLEMENTS" ]; then
        codesign --force --sign "Developer ID Application" \
            --entitlements "$EXTENSION_ENTITLEMENTS" \
            --options runtime \
            --timestamp \
            "$EXTENSION_PATH"
        print_success "Extension signed with distribution entitlements"
    else
        print_error "Extension entitlements not found: $EXTENSION_ENTITLEMENTS"
        exit 1
    fi
else
    print_error "System extension not found"
    exit 1
fi

# Step 4: Sign the main app
print_status "Step 4: Signing main app with entitlements..."
APP_ENTITLEMENTS="$PROJECT_ROOT/GigECameraApp/GigECamera-Distribution.entitlements"

if [ -f "$APP_ENTITLEMENTS" ]; then
    codesign --force --sign "Developer ID Application" \
        --entitlements "$APP_ENTITLEMENTS" \
        --options runtime \
        --timestamp \
        "$WORK_APP"
    print_success "App signed with distribution entitlements"
else
    print_error "App entitlements not found: $APP_ENTITLEMENTS"
    exit 1
fi

# Step 5: Verify signatures
print_status "Step 5: Verifying signatures..."

# Verify extension
if codesign --verify --deep --strict "$EXTENSION_PATH" 2>&1; then
    print_success "Extension signature valid"
else
    print_error "Extension signature invalid"
    exit 1
fi

# Verify app
if codesign --verify --deep --strict "$WORK_APP" 2>&1; then
    print_success "App signature valid"
else
    print_error "App signature invalid"
    exit 1
fi

# Step 6: Check entitlements
print_status "Step 6: Verifying entitlements..."
echo ""
echo "Extension entitlements:"
codesign -d --entitlements - "$EXTENSION_PATH" 2>&1 | grep -A2 "application-groups" || true
echo ""
echo "App entitlements:"
codesign -d --entitlements - "$WORK_APP" 2>&1 | grep -A2 "application-groups" || true
echo ""

# Step 7: Replace original app
print_status "Step 7: Replacing original app..."
rm -rf "$APP_PATH"
cp -R "$WORK_APP" "$APP_PATH"
print_success "App replaced in /Applications"

# Clean up
rm -rf "$TEMP_DIR"

echo ""
print_success "🎉 Re-signing complete!"
echo ""
echo "The app has been re-signed with proper entitlements for distribution."
echo ""
echo "Next steps:"
echo "1. Test the extension installation"
echo "2. If successful, run: ./Scripts/notarize.sh /Applications/GigEVirtualCamera.app"
echo "3. Create DMG: ./Scripts/create_dmg.sh /Applications/GigEVirtualCamera.app"
echo ""