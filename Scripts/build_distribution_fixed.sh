#!/bin/bash

# build_distribution_fixed.sh - Build and sign for Developer ID distribution with fixed entitlements
# This script ensures proper signing for system extension validation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"

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
echo "🚀 Building GigE Virtual Camera for Distribution"
echo "==============================================="
echo ""

# Step 1: Clean build directory
print_status "Step 1: Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
print_success "Build directory cleaned"

# Step 2: Build with Release configuration
print_status "Step 2: Building Release configuration..."
cd "$PROJECT_ROOT"

xcodebuild -project GigEVirtualCamera.xcodeproj \
    -scheme GigEVirtualCamera \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    DEVELOPMENT_TEAM="${APPLE_TEAM_ID:-S368GH6KF7}" \
    CODE_SIGN_STYLE="Automatic" \
    ENABLE_HARDENED_RUNTIME="YES" \
    clean build

print_success "Build completed"

# Step 3: Copy app to temporary location for signing
print_status "Step 3: Preparing app for signing..."
BUILT_APP="$BUILD_DIR/DerivedData/Build/Products/Release/GigEVirtualCamera.app"
TEMP_APP="$BUILD_DIR/GigEVirtualCamera.app"

if [ -d "$BUILT_APP" ]; then
    cp -R "$BUILT_APP" "$TEMP_APP"
    print_success "App copied to: $TEMP_APP"
else
    print_error "Built app not found at: $BUILT_APP"
    exit 1
fi

# Step 4: Remove all provisioning profiles
print_status "Step 4: Removing embedded provisioning profiles..."
find "$TEMP_APP" -name "*.provisionprofile" -o -name "embedded.provisionprofile" | while read profile; do
    rm -f "$profile"
    print_success "Removed: $(basename "$profile")"
done

# Step 5: Sign the extension with proper entitlements
print_status "Step 5: Signing system extension..."
EXTENSION_PATH="$TEMP_APP/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
EXTENSION_ENTITLEMENTS="$PROJECT_ROOT/GigEVirtualCameraExtension/GigEVirtualCameraExtension-Distribution.entitlements"

if [ -d "$EXTENSION_PATH" ]; then
    # First sign any embedded frameworks/libraries in the extension
    find "$EXTENSION_PATH" -name "*.dylib" -o -name "*.framework" | while read lib; do
        codesign --force --sign "Developer ID Application" \
            --options runtime \
            --timestamp \
            "$lib"
    done
    
    # Then sign the extension itself
    codesign --force --sign "Developer ID Application" \
        --entitlements "$EXTENSION_ENTITLEMENTS" \
        --options runtime \
        --timestamp \
        "$EXTENSION_PATH"
    print_success "Extension signed with entitlements"
else
    print_error "System extension not found"
    exit 1
fi

# Step 6: Sign the main app
print_status "Step 6: Signing main app..."
APP_ENTITLEMENTS="$PROJECT_ROOT/GigECameraApp/GigECamera-Distribution.entitlements"

# Sign embedded Aravis libraries first
ARAVIS_DIR="$TEMP_APP/Contents/Frameworks"
if [ -d "$ARAVIS_DIR" ]; then
    find "$ARAVIS_DIR" -name "*.dylib" | while read lib; do
        codesign --force --sign "Developer ID Application" \
            --options runtime \
            --timestamp \
            "$lib"
    done
fi

# Sign the app (without --deep to preserve extension signature)
codesign --force --sign "Developer ID Application" \
    --entitlements "$APP_ENTITLEMENTS" \
    --options runtime \
    --timestamp \
    "$TEMP_APP"

print_success "App signed with distribution entitlements"

# Step 7: Verify signatures
print_status "Step 7: Verifying signatures..."

# Verify extension
if codesign --verify --deep --strict "$EXTENSION_PATH" 2>&1; then
    print_success "Extension signature valid"
else
    print_error "Extension signature invalid"
    exit 1
fi

# Verify app
if codesign --verify --deep --strict "$TEMP_APP" 2>&1; then
    print_success "App signature valid"
else
    print_error "App signature invalid"
    exit 1
fi

# Check entitlements
print_status "Checking entitlements..."
echo "Extension entitlements:"
codesign -d --entitlements - "$EXTENSION_PATH" 2>&1 | grep -E "app-sandbox|application-groups" || true
echo ""
echo "App entitlements:"
codesign -d --entitlements - "$TEMP_APP" 2>&1 | grep -E "system-extension|application-groups" || true

# Step 8: Move to Applications
print_status "Step 8: Installing to /Applications..."
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    print_status "Removing existing app..."
    rm -rf "/Applications/GigEVirtualCamera.app"
fi

cp -R "$TEMP_APP" "/Applications/GigEVirtualCamera.app"
print_success "App installed to /Applications/GigEVirtualCamera.app"

echo ""
print_success "🎉 Distribution build complete!"
echo ""
echo "Next steps:"
echo "1. Run: ./Scripts/notarize.sh /Applications/GigEVirtualCamera.app"
echo "2. Test the extension installation"
echo "3. Create DMG: ./Scripts/create_dmg.sh /Applications/GigEVirtualCamera.app"
echo ""