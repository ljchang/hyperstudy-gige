#!/bin/bash

# build_and_distribute.sh - Streamlined distribution build process
# This script builds, signs, notarizes, and packages the app for distribution
# Prerequisites: Developer ID provisioning profiles configured in Xcode

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_DIR="$PROJECT_ROOT/build/distribution"

# Signing configuration
TEAM_ID="S368GH6KF7"
SIGNING_IDENTITY="Developer ID Application: Luke  Chang (S368GH6KF7)"

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

# Step 1: Clean and prepare
print_status "Step 1: Cleaning build environment..."
rm -rf "$BUILD_DIR"
rm -rf "$OUTPUT_DIR"
rm -rf /Applications/GigEVirtualCamera.app
mkdir -p "$OUTPUT_DIR"
print_success "Environment cleaned"

# Step 2: Build with Release configuration
print_status "Step 2: Building Release configuration..."
cd "$PROJECT_ROOT"

xcodebuild -project GigEVirtualCamera.xcodeproj \
    -scheme GigEVirtualCamera \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -destination "generic/platform=macOS" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE="Manual" \
    clean build

print_success "Build completed"

# Step 3: Copy app to Applications
print_status "Step 3: Installing to Applications..."
BUILT_APP="$BUILD_DIR/DerivedData/Build/Products/Release/GigEVirtualCamera.app"

if [ ! -d "$BUILT_APP" ]; then
    print_error "Built app not found at: $BUILT_APP"
    exit 1
fi

cp -R "$BUILT_APP" /Applications/GigEVirtualCamera.app
APP_PATH="/Applications/GigEVirtualCamera.app"

# Fix any nested app bundle issue (build system sometimes creates this)
if [ -d "$APP_PATH/GigEVirtualCamera.app" ]; then
    print_warning "Fixing nested app bundle issue..."
    rm -rf "$APP_PATH/GigEVirtualCamera.app"
fi

print_success "App installed to /Applications"

# Step 4: Verify and fix provisioning profiles
print_status "Step 4: Ensuring provisioning profiles are embedded..."
EXTENSION_PATH="$APP_PATH/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"

# For Developer ID distribution with restricted entitlements, we MUST have provisioning profiles
# Check and embed the app provisioning profile if missing
if [ ! -f "$APP_PATH/Contents/embedded.provisionprofile" ]; then
    print_warning "App provisioning profile missing - searching for correct profile..."
    
    # Look for the Developer ID provisioning profile for the app
    PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
    DROPBOX_PROFILES="/Users/lukechang/Dartmouth College Dropbox/Luke Chang/HyperStudy/GigE/ProvisioningProfile"
    APP_PROFILE=""
    
    # Find profile by searching for bundle ID in the profile content
    for profile in "$PROFILES_DIR"/*.provisionprofile; do
        if [ -f "$profile" ]; then
            # Decode the profile and check if it contains our bundle ID and is Developer ID type
            if security cms -D -i "$profile" 2>/dev/null | grep -q "com.lukechang.GigEVirtualCamera" && \
               security cms -D -i "$profile" 2>/dev/null | grep -q "Developer ID"; then
                # Also check it's not the extension profile
                if ! security cms -D -i "$profile" 2>/dev/null | grep -q "com.lukechang.GigEVirtualCamera.Extension"; then
                    APP_PROFILE="$profile"
                    break
                fi
            fi
        fi
    done
    
    if [ -n "$APP_PROFILE" ]; then
        cp "$APP_PROFILE" "$APP_PATH/Contents/embedded.provisionprofile"
        print_success "Embedded app Developer ID provisioning profile"
    else
        # Try the Dropbox location
        if [ -f "$DROPBOX_PROFILES/GigE_Virtual_Camera_Distribution.provisionprofile" ]; then
            cp "$DROPBOX_PROFILES/GigE_Virtual_Camera_Distribution.provisionprofile" "$APP_PATH/Contents/embedded.provisionprofile"
            print_success "Embedded app Developer ID provisioning profile from Dropbox"
        else
            print_error "No Developer ID provisioning profile found for app bundle ID"
            print_info "Please ensure you have a Developer ID provisioning profile for com.lukechang.GigEVirtualCamera"
            print_info "Searched in:"
            print_info "  - $PROFILES_DIR"
            print_info "  - $DROPBOX_PROFILES"
            exit 1
        fi
    fi
else
    # Verify it's a Developer ID profile
    if security cms -D -i "$APP_PATH/Contents/embedded.provisionprofile" 2>/dev/null | grep -q "Developer ID"; then
        print_success "App has Developer ID provisioning profile"
    else
        print_warning "App has provisioning profile but it's not Developer ID type"
    fi
fi

# Check extension provisioning profile
if [ -f "$EXTENSION_PATH/Contents/embedded.provisionprofile" ]; then
    if security cms -D -i "$EXTENSION_PATH/Contents/embedded.provisionprofile" 2>/dev/null | grep -q "Developer ID"; then
        print_success "Extension has Developer ID provisioning profile"
    else
        print_warning "Extension has provisioning profile but it may not be Developer ID type"
    fi
else
    print_error "No extension provisioning profile found"
    exit 1
fi

# Step 5: Clean up and re-sign properly
print_status "Step 5: Cleaning and ensuring proper code signing..."

# Remove any .DS_Store or other hidden files that might cause issues
find "$APP_PATH" -name ".DS_Store" -delete 2>/dev/null || true
find "$APP_PATH" -name "._*" -delete 2>/dev/null || true

# Sign Aravis libraries
if [ -d "$APP_PATH/Contents/Frameworks" ]; then
    find "$APP_PATH/Contents/Frameworks" -name "*.dylib" | while read lib; do
        codesign --force --sign "$SIGNING_IDENTITY" \
            --timestamp \
            --options runtime \
            "$lib"
    done
    print_success "Libraries signed"
fi

# Re-sign extension with its entitlements
EXTENSION_ENTITLEMENTS="$PROJECT_ROOT/GigEVirtualCameraExtension/GigEVirtualCameraExtension-Distribution.entitlements"
if [ -f "$EXTENSION_ENTITLEMENTS" ]; then
    # First remove existing signature
    codesign --remove-signature "$EXTENSION_PATH" 2>/dev/null || true
    
    codesign --force --sign "$SIGNING_IDENTITY" \
        --entitlements "$EXTENSION_ENTITLEMENTS" \
        --timestamp \
        --options runtime \
        "$EXTENSION_PATH"
    print_success "Extension re-signed"
fi

# Re-sign app with its entitlements
APP_ENTITLEMENTS="$PROJECT_ROOT/GigECameraApp/GigECamera-Distribution.entitlements"
if [ -f "$APP_ENTITLEMENTS" ]; then
    # First remove existing signature
    codesign --remove-signature "$APP_PATH" 2>/dev/null || true
    
    codesign --force --sign "$SIGNING_IDENTITY" \
        --entitlements "$APP_ENTITLEMENTS" \
        --timestamp \
        --options runtime \
        "$APP_PATH"
    print_success "App re-signed"
fi

# Step 6: Verify signatures
print_status "Step 6: Verifying signatures..."
if codesign --verify --deep --strict "$APP_PATH" 2>&1; then
    print_success "App signature valid"
else
    print_error "App signature invalid"
    exit 1
fi

# Step 7: Notarize the app
print_status "Step 7: Notarizing application..."

# Check notarization credentials
if ! xcrun notarytool store-credentials --list 2>&1 | grep -q "GigE-Notarization"; then
    print_warning "Setting up notarization credentials..."
    "$SCRIPT_DIR/setup_notarization.sh"
fi

# Submit for notarization
print_status "Submitting for notarization (this may take 5-15 minutes)..."
NOTARIZE_OUTPUT=$(xcrun notarytool submit "$APP_PATH" \
    --keychain-profile "GigE-Notarization" \
    --wait 2>&1)

if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
    print_success "Notarization accepted"
    
    # Staple the ticket
    if xcrun stapler staple "$APP_PATH"; then
        print_success "Notarization ticket stapled"
    else
        print_error "Failed to staple ticket"
        exit 1
    fi
else
    print_error "Notarization failed"
    echo "$NOTARIZE_OUTPUT"
    
    # Get the log for debugging
    SUBMISSION_ID=$(echo "$NOTARIZE_OUTPUT" | grep -E "^\s*id:" | head -1 | awk '{print $2}')
    if [ -n "$SUBMISSION_ID" ]; then
        print_status "Fetching notarization log..."
        xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "GigE-Notarization"
    fi
    exit 1
fi

# Step 8: Create DMG
print_status "Step 8: Creating DMG..."

# Get version info
APP_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")

# Create temp directory for DMG
DMG_TEMP="$BUILD_DIR/dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app and create Applications symlink
cp -R "$APP_PATH" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
DMG_PATH="$OUTPUT_DIR/GigEVirtualCamera-$APP_VERSION.dmg"
hdiutil create -volname "GigE Virtual Camera" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

# Sign DMG
codesign --force --sign "$SIGNING_IDENTITY" "$DMG_PATH"
print_success "DMG created and signed"

# Step 9: Notarize DMG
print_status "Step 9: Notarizing DMG..."
NOTARIZE_OUTPUT=$(xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "GigE-Notarization" \
    --wait 2>&1)

if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
    print_success "DMG notarization accepted"
    
    if xcrun stapler staple "$DMG_PATH"; then
        print_success "Notarization ticket stapled to DMG"
    else
        print_error "Failed to staple ticket to DMG"
        exit 1
    fi
else
    print_error "DMG notarization failed"
    echo "$NOTARIZE_OUTPUT"
    exit 1
fi

# Step 10: Final verification
print_status "Step 10: Final verification..."
if spctl -a -vvv "$DMG_PATH" 2>&1 | grep -q "source=Notarized Developer ID"; then
    print_success "DMG verification passed"
else
    print_warning "DMG verification returned unexpected result"
fi

# Create distribution info
DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
BUILD_NUMBER=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "1")

cat > "$OUTPUT_DIR/distribution-info.txt" << EOF
GigE Virtual Camera Distribution
================================
Version: $APP_VERSION (Build $BUILD_NUMBER)
Date: $(date)
DMG: $(basename "$DMG_PATH") ($DMG_SIZE)
Status: ✅ Ready for distribution

Installation:
1. Download and open the DMG
2. Drag GigEVirtualCamera to Applications
3. Launch and approve system extension
4. Virtual camera ready to use!

Verified on: macOS $(sw_vers -productVersion)
Architecture: Apple Silicon (arm64)
EOF

# Done!
echo ""
echo "============================================"
print_success "🎉 Distribution build complete!"
echo "============================================"
echo ""
echo "📦 Distribution package:"
echo "   $DMG_PATH ($DMG_SIZE)"
echo ""
echo "✅ Code signed with Developer ID"
echo "✅ Notarized and stapled"
echo "✅ Ready for distribution"
echo ""
echo "Test on another Mac by:"
echo "1. Copying the DMG file"
echo "2. Double-clicking to mount"
echo "3. Installing and running"
echo ""

# Open the distribution folder
open "$OUTPUT_DIR"

print_success "Distribution complete! 🚀"