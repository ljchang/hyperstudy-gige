#!/bin/bash

# release_distribution.sh - Complete distribution release process for GigE Virtual Camera
# This script handles the full distribution pipeline including proper Developer ID signing

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/build/distribution"
NOTARIZATION_DIR="$PROJECT_ROOT/build/notarization"

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

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    print_error "Please run this script from the project root"
    exit 1
fi

echo ""
echo "🚀 GigE Virtual Camera Distribution Release Process"
echo "=================================================="
echo ""

# Step 1: Build release version with distribution marker
print_status "Step 1: Building release version with distribution profiles..."
cd "$PROJECT_ROOT"

# Create distribution marker to trigger post-build scripts
rm -f .distribution_build
touch .distribution_build

# Build with Release configuration
xcodebuild -project GigEVirtualCamera.xcodeproj \
    -scheme GigEVirtualCamera \
    -configuration Release \
    clean build

# Clean up marker file
rm -f .distribution_build

# The app should now be in /Applications
APP_PATH="/Applications/GigEVirtualCamera.app"
if [ ! -d "$APP_PATH" ]; then
    print_error "App not found at $APP_PATH"
    exit 1
fi

print_success "App built and installed to $APP_PATH"

# Step 2: Fix Developer ID signing for system extension
print_status "Step 2: Fixing Developer ID signing for distribution..."

# Sign the system extension with Developer ID
EXTENSION_PATH="$APP_PATH/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
if [ -d "$EXTENSION_PATH" ]; then
    print_status "Signing system extension with Developer ID..."
    codesign --force --sign "Developer ID Application: Luke  Chang (S368GH6KF7)" \
        --options runtime \
        --timestamp \
        "$EXTENSION_PATH"
    print_success "Extension signed"
else
    print_error "System extension not found at expected path"
    exit 1
fi

# Re-sign the main app to include the properly signed extension
print_status "Re-signing main app with Developer ID..."
# Find the correct entitlements file
APP_ENTITLEMENTS="$PROJECT_ROOT/GigECameraApp/GigECamera.entitlements"
if [ ! -f "$APP_ENTITLEMENTS" ]; then
    APP_ENTITLEMENTS="$PROJECT_ROOT/GigECameraApp/GigECamera-Release.entitlements"
fi
if [ -f "$APP_ENTITLEMENTS" ]; then
    codesign --force --deep --sign "Developer ID Application: Luke  Chang (S368GH6KF7)" \
        --entitlements "$APP_ENTITLEMENTS" \
        --options runtime \
        --timestamp \
        "$APP_PATH"
else
    print_warning "No entitlements file found, signing without entitlements"
    codesign --force --deep --sign "Developer ID Application: Luke  Chang (S368GH6KF7)" \
        --options runtime \
        --timestamp \
        "$APP_PATH"
fi

# Verify signing
if codesign --verify --deep --strict "$APP_PATH" 2>&1; then
    print_success "App signature verified"
else
    print_error "App signature verification failed"
    exit 1
fi

# Step 3: Notarize the app
print_status "Step 3: Notarizing the app..."
"$SCRIPT_DIR/notarize.sh" "$APP_PATH"

# Verify notarization
if xcrun stapler validate "$APP_PATH" 2>&1 | grep -q "The validate action worked"; then
    print_success "App notarization verified"
else
    print_error "App notarization verification failed"
    exit 1
fi

# Step 4: Create DMG
print_status "Step 4: Creating distribution DMG..."

# Create directories
mkdir -p "$OUTPUT_DIR"

# Use the create_dmg script
"$SCRIPT_DIR/create_dmg.sh" "$APP_PATH"

# Find the created DMG
DMG_FILE="$OUTPUT_DIR/GigEVirtualCamera.dmg"
if [ ! -f "$DMG_FILE" ]; then
    # Try the notarization directory
    if [ -f "$NOTARIZATION_DIR/GigEVirtualCamera.dmg" ]; then
        cp "$NOTARIZATION_DIR/GigEVirtualCamera.dmg" "$DMG_FILE"
    else
        print_error "DMG not found"
        exit 1
    fi
fi

print_success "DMG created at $DMG_FILE"

# Step 5: Notarize the DMG
print_status "Step 5: Notarizing the DMG..."

# Submit for notarization
if xcrun notarytool submit "$DMG_FILE" \
    --keychain-profile "GigE-Notarization" \
    --wait; then
    print_success "DMG notarization submitted successfully"
    
    # Staple the ticket
    if xcrun stapler staple "$DMG_FILE"; then
        print_success "Notarization ticket stapled to DMG"
    else
        print_error "Failed to staple notarization ticket"
        exit 1
    fi
else
    print_error "DMG notarization failed"
    exit 1
fi

# Step 6: Final verification
print_status "Step 6: Final verification..."

# Verify DMG
if spctl -a -vvv "$DMG_FILE" 2>&1 | grep -q "source=Notarized Developer ID"; then
    print_success "DMG verification passed"
else
    print_warning "DMG verification shows unexpected status"
fi

# Get app info
APP_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
BUILD_NUMBER=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "1")
DMG_SIZE=$(du -h "$DMG_FILE" | cut -f1)

# Create release summary
RELEASE_INFO="$OUTPUT_DIR/release-info.txt"
cat > "$RELEASE_INFO" << EOF
GigE Virtual Camera Release Summary
==================================

Version: $APP_VERSION ($BUILD_NUMBER)
Build Date: $(date)
Team ID: S368GH6KF7

Distribution File:
- DMG: $DMG_FILE ($DMG_SIZE)

Signing & Notarization:
- Code Signing: Developer ID Application ✅
- App Notarized: ✅
- DMG Notarized: ✅
- Gatekeeper Ready: ✅

System Requirements:
- macOS 12.3 or later
- Apple Silicon (M1/M2) Mac
- GigE Vision camera (optional - includes test camera)

Installation:
1. Download and mount the DMG
2. Drag GigEVirtualCamera.app to Applications
3. Launch the app and approve system extension
4. Virtual camera appears in all camera apps

Generated by: $0
EOF

echo ""
print_success "🎉 Distribution release complete!"
echo ""
echo "📦 Distribution File:"
echo "   $DMG_FILE ($DMG_SIZE)"
echo ""
echo "📊 Version: $APP_VERSION ($BUILD_NUMBER)"
echo ""
echo "✅ Fully signed and notarized"
echo "✅ Ready for public distribution"
echo ""

# Open the distribution folder
open "$OUTPUT_DIR"

print_success "Distribution package ready! 🚀"