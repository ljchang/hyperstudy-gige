#!/bin/bash

# build_complete_distribution.sh - Complete distribution build with proper provisioning profiles
# This unified script handles the entire distribution process correctly
#
# IMPORTANT: Before running this script, ensure you have:
# 1. Developer ID provisioning profiles for both the app and extension
# 2. These profiles must include the system extension entitlement
# 3. Profiles should be installed in ~/Library/MobileDevice/Provisioning Profiles/

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_DIR="$PROJECT_ROOT/build/distribution"
TEMP_DIR="$PROJECT_ROOT/build/temp"

# Team and signing configuration
TEAM_ID="S368GH6KF7"
SIGNING_IDENTITY="Developer ID Application: Luke  Chang (S368GH6KF7)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_info() {
    echo -e "${PURPLE}ℹ️${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools not found"
        exit 1
    fi
    
    # Check for notarytool
    if ! xcrun notarytool --help &> /dev/null; then
        print_error "notarytool not found. Please install Xcode 13 or later"
        exit 1
    fi
    
    # Check for provisioning profiles
    PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
    if [ ! -d "$PROFILES_DIR" ]; then
        print_error "Provisioning profiles directory not found"
        print_info "Please install Developer ID provisioning profiles from Apple Developer Portal"
        exit 1
    fi
    
    # Check if we have any GigE related profiles
    if ! ls "$PROFILES_DIR"/*.provisionprofile 2>/dev/null | grep -qi gige; then
        print_warning "No GigE provisioning profiles found in $PROFILES_DIR"
        print_info "Make sure you have Developer ID provisioning profiles installed"
    fi
    
    print_success "Prerequisites check passed"
}

# Clean build environment
clean_build() {
    print_status "Cleaning build environment..."
    rm -rf "$BUILD_DIR"
    rm -rf "$OUTPUT_DIR"
    rm -rf "$TEMP_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$TEMP_DIR"
    
    # Remove any existing app
    if [ -d "/Applications/GigEVirtualCamera.app" ]; then
        print_status "Removing existing app from /Applications..."
        rm -rf "/Applications/GigEVirtualCamera.app"
    fi
    
    print_success "Build environment cleaned"
}

# Build the application
build_app() {
    print_status "Building GigE Virtual Camera for distribution..."
    cd "$PROJECT_ROOT"
    
    # First, let's check the project for provisioning profile settings
    print_info "Checking project configuration..."
    
    # Build with automatic signing to get proper provisioning profiles
    xcodebuild -project GigEVirtualCamera.xcodeproj \
        -scheme GigEVirtualCamera \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        -destination "generic/platform=macOS" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
        CODE_SIGN_STYLE="Manual" \
        PROVISIONING_PROFILE_SPECIFIER="" \
        CODE_SIGN_INJECT_BASE_ENTITLEMENTS="NO" \
        OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
        ENABLE_HARDENED_RUNTIME="YES" \
        clean build
    
    print_success "Build completed"
}

# Copy and prepare the app
prepare_app() {
    print_status "Preparing app for distribution..."
    
    BUILT_APP="$BUILD_DIR/DerivedData/Build/Products/Release/GigEVirtualCamera.app"
    WORK_APP="$TEMP_DIR/GigEVirtualCamera.app"
    
    if [ ! -d "$BUILT_APP" ]; then
        print_error "Built app not found at: $BUILT_APP"
        exit 1
    fi
    
    cp -R "$BUILT_APP" "$WORK_APP"
    print_success "App copied to working directory"
    
    # Check if provisioning profiles were embedded
    print_status "Checking for embedded provisioning profiles..."
    if [ -f "$WORK_APP/Contents/embedded.provisionprofile" ]; then
        print_success "App provisioning profile found"
    else
        print_warning "No app provisioning profile embedded - will need to embed manually"
    fi
    
    EXTENSION_PATH="$WORK_APP/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
    if [ -f "$EXTENSION_PATH/Contents/embedded.provisionprofile" ]; then
        print_success "Extension provisioning profile found"
    else
        print_warning "No extension provisioning profile embedded - will need to embed manually"
    fi
}

# Embed provisioning profiles if needed
embed_provisioning_profiles() {
    print_status "Ensuring provisioning profiles are embedded..."
    
    PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
    WORK_APP="$TEMP_DIR/GigEVirtualCamera.app"
    EXTENSION_PATH="$WORK_APP/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
    
    # Find and embed app provisioning profile
    if [ ! -f "$WORK_APP/Contents/embedded.provisionprofile" ]; then
        print_status "Looking for app provisioning profile..."
        # Look for Developer ID profile for the app
        APP_PROFILE=$(find "$PROFILES_DIR" -name "*.provisionprofile" -exec grep -l "com.lukechang.GigEVirtualCamera" {} \; | grep -i "developer id" | head -1)
        
        if [ -z "$APP_PROFILE" ]; then
            # Try any profile with the app bundle ID
            APP_PROFILE=$(find "$PROFILES_DIR" -name "*.provisionprofile" -exec grep -l "com.lukechang.GigEVirtualCamera" {} \; | head -1)
        fi
        
        if [ -n "$APP_PROFILE" ] && [ -f "$APP_PROFILE" ]; then
            cp "$APP_PROFILE" "$WORK_APP/Contents/embedded.provisionprofile"
            print_success "Embedded app provisioning profile"
        else
            print_error "No suitable app provisioning profile found"
            print_info "Please download Developer ID provisioning profile from Apple Developer Portal"
            exit 1
        fi
    fi
    
    # Find and embed extension provisioning profile
    if [ ! -f "$EXTENSION_PATH/Contents/embedded.provisionprofile" ]; then
        print_status "Looking for extension provisioning profile..."
        # Look for Developer ID profile for the extension
        EXT_PROFILE=$(find "$PROFILES_DIR" -name "*.provisionprofile" -exec grep -l "com.lukechang.GigEVirtualCamera.Extension" {} \; | grep -i "developer id" | head -1)
        
        if [ -z "$EXT_PROFILE" ]; then
            # Try any profile with the extension bundle ID
            EXT_PROFILE=$(find "$PROFILES_DIR" -name "*.provisionprofile" -exec grep -l "com.lukechang.GigEVirtualCamera.Extension" {} \; | head -1)
        fi
        
        if [ -n "$EXT_PROFILE" ] && [ -f "$EXT_PROFILE" ]; then
            cp "$EXT_PROFILE" "$EXTENSION_PATH/Contents/embedded.provisionprofile"
            print_success "Embedded extension provisioning profile"
        else
            print_error "No suitable extension provisioning profile found"
            print_info "Please download Developer ID provisioning profile for the extension from Apple Developer Portal"
            exit 1
        fi
    fi
}

# Sign the application properly
sign_app() {
    print_status "Signing application for distribution..."
    
    WORK_APP="$TEMP_DIR/GigEVirtualCamera.app"
    EXTENSION_PATH="$WORK_APP/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
    
    # Sign Aravis libraries first
    print_status "Signing embedded libraries..."
    if [ -d "$WORK_APP/Contents/Frameworks" ]; then
        find "$WORK_APP/Contents/Frameworks" -name "*.dylib" -o -name "*.framework" | while read lib; do
            codesign --force --sign "$SIGNING_IDENTITY" \
                --timestamp \
                --options runtime \
                "$lib"
        done
        print_success "Libraries signed"
    fi
    
    # Sign the extension with its entitlements
    print_status "Signing system extension..."
    EXTENSION_ENTITLEMENTS="$PROJECT_ROOT/GigEVirtualCameraExtension/GigEVirtualCameraExtension-Distribution.entitlements"
    
    if [ ! -f "$EXTENSION_ENTITLEMENTS" ]; then
        print_error "Extension entitlements not found: $EXTENSION_ENTITLEMENTS"
        exit 1
    fi
    
    codesign --force --sign "$SIGNING_IDENTITY" \
        --entitlements "$EXTENSION_ENTITLEMENTS" \
        --timestamp \
        --options runtime \
        --preserve-metadata=identifier,entitlements,requirements \
        "$EXTENSION_PATH"
    
    print_success "Extension signed"
    
    # Sign the main app
    print_status "Signing main application..."
    APP_ENTITLEMENTS="$PROJECT_ROOT/GigECameraApp/GigECamera-Distribution.entitlements"
    
    if [ ! -f "$APP_ENTITLEMENTS" ]; then
        print_error "App entitlements not found: $APP_ENTITLEMENTS"
        exit 1
    fi
    
    codesign --force --sign "$SIGNING_IDENTITY" \
        --entitlements "$APP_ENTITLEMENTS" \
        --timestamp \
        --options runtime \
        --preserve-metadata=identifier,entitlements,requirements \
        "$WORK_APP"
    
    print_success "Application signed"
}

# Verify the app
verify_app() {
    print_status "Verifying application signatures..."
    
    WORK_APP="$TEMP_DIR/GigEVirtualCamera.app"
    EXTENSION_PATH="$WORK_APP/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
    
    # Verify extension
    if codesign --verify --deep --strict "$EXTENSION_PATH" 2>&1; then
        print_success "Extension signature valid"
    else
        print_error "Extension signature invalid"
        codesign --verify --deep --verbose "$EXTENSION_PATH"
        exit 1
    fi
    
    # Verify app
    if codesign --verify --deep --strict "$WORK_APP" 2>&1; then
        print_success "App signature valid"
    else
        print_error "App signature invalid"
        codesign --verify --deep --verbose "$WORK_APP"
        exit 1
    fi
    
    # Check provisioning profiles
    if [ -f "$WORK_APP/Contents/embedded.provisionprofile" ]; then
        print_success "App provisioning profile present"
    else
        print_error "App provisioning profile missing!"
        exit 1
    fi
    
    if [ -f "$EXTENSION_PATH/Contents/embedded.provisionprofile" ]; then
        print_success "Extension provisioning profile present"
    else
        print_error "Extension provisioning profile missing!"
        exit 1
    fi
    
    print_success "Verification complete"
}

# Install to Applications
install_app() {
    print_status "Installing to /Applications..."
    
    WORK_APP="$TEMP_DIR/GigEVirtualCamera.app"
    cp -R "$WORK_APP" "/Applications/GigEVirtualCamera.app"
    
    print_success "App installed to /Applications"
}

# Notarize the app
notarize_app() {
    print_status "Notarizing application..."
    
    APP_PATH="/Applications/GigEVirtualCamera.app"
    
    # Check if notarization keychain profile exists
    if ! xcrun notarytool store-credentials --list 2>&1 | grep -q "GigE-Notarization"; then
        print_warning "Notarization profile 'GigE-Notarization' not found"
        print_info "Setting up notarization profile..."
        "$SCRIPT_DIR/setup_notarization.sh"
    fi
    
    # Submit for notarization
    print_status "Submitting app for notarization (this may take 5-15 minutes)..."
    NOTARIZE_OUTPUT=$(xcrun notarytool submit "$APP_PATH" \
        --keychain-profile "GigE-Notarization" \
        --wait 2>&1)
    
    if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
        print_success "App notarization accepted"
        
        # Staple the ticket
        print_status "Stapling notarization ticket..."
        if xcrun stapler staple "$APP_PATH"; then
            print_success "Notarization ticket stapled"
        else
            print_error "Failed to staple notarization ticket"
            exit 1
        fi
    else
        print_error "App notarization failed"
        echo "$NOTARIZE_OUTPUT"
        
        # Try to get the log
        SUBMISSION_ID=$(echo "$NOTARIZE_OUTPUT" | grep -E "^\s*id:" | head -1 | awk '{print $2}')
        if [ -n "$SUBMISSION_ID" ]; then
            print_info "Getting notarization log..."
            xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "GigE-Notarization"
        fi
        exit 1
    fi
}

# Create DMG
create_dmg() {
    print_status "Creating distribution DMG..."
    
    APP_PATH="/Applications/GigEVirtualCamera.app"
    DMG_PATH="$OUTPUT_DIR/GigEVirtualCamera.dmg"
    
    # Get app version
    APP_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
    
    # Create a temporary directory for DMG contents
    DMG_TEMP="$TEMP_DIR/dmg"
    mkdir -p "$DMG_TEMP"
    
    # Copy app to DMG directory
    cp -R "$APP_PATH" "$DMG_TEMP/"
    
    # Create Applications symlink
    ln -s /Applications "$DMG_TEMP/Applications"
    
    # Create DMG
    hdiutil create -volname "GigE Virtual Camera $APP_VERSION" \
        -srcfolder "$DMG_TEMP" \
        -ov -format UDZO \
        "$DMG_PATH"
    
    print_success "DMG created"
    
    # Sign the DMG
    print_status "Signing DMG..."
    codesign --force --sign "$SIGNING_IDENTITY" "$DMG_PATH"
    print_success "DMG signed"
}

# Notarize DMG
notarize_dmg() {
    print_status "Notarizing DMG..."
    
    DMG_PATH="$OUTPUT_DIR/GigEVirtualCamera.dmg"
    
    # Submit for notarization
    print_status "Submitting DMG for notarization..."
    NOTARIZE_OUTPUT=$(xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "GigE-Notarization" \
        --wait 2>&1)
    
    if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
        print_success "DMG notarization accepted"
        
        # Staple the ticket
        print_status "Stapling notarization ticket to DMG..."
        if xcrun stapler staple "$DMG_PATH"; then
            print_success "Notarization ticket stapled to DMG"
        else
            print_error "Failed to staple notarization ticket"
            exit 1
        fi
    else
        print_error "DMG notarization failed"
        echo "$NOTARIZE_OUTPUT"
        exit 1
    fi
}

# Create release summary
create_release_summary() {
    print_status "Creating release summary..."
    
    APP_PATH="/Applications/GigEVirtualCamera.app"
    DMG_PATH="$OUTPUT_DIR/GigEVirtualCamera.dmg"
    
    APP_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
    BUILD_NUMBER=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "1")
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    
    SUMMARY_PATH="$OUTPUT_DIR/release-summary.txt"
    
    cat > "$SUMMARY_PATH" << EOF
GigE Virtual Camera Distribution Build Summary
===========================================

Version: $APP_VERSION (Build $BUILD_NUMBER)
Date: $(date)
Team: Luke Chang ($TEAM_ID)

Files:
- Application: /Applications/GigEVirtualCamera.app
- Distribution: $DMG_PATH ($DMG_SIZE)

Status:
- Code Signing: ✅ Developer ID
- Provisioning Profiles: ✅ Embedded
- App Notarization: ✅ Complete
- DMG Notarization: ✅ Complete
- Ready for Distribution: ✅ YES

Requirements:
- macOS 12.3 or later
- Apple Silicon Mac
- GigE Vision camera (optional - test camera included)

Installation Instructions:
1. Download the DMG file
2. Double-click to mount
3. Drag GigEVirtualCamera to Applications
4. Launch and approve system extension when prompted
5. Virtual camera will appear in all camera apps

Testing on Another Mac:
1. Copy the DMG to the target Mac
2. Double-click to mount (should not show any warnings)
3. Install and run the app
4. If issues occur, run: ./Scripts/diagnose_runtime_error.sh

Build Command: $0
EOF
    
    print_success "Release summary created: $SUMMARY_PATH"
}

# Main execution
main() {
    echo ""
    echo "🚀 GigE Virtual Camera Complete Distribution Build"
    echo "================================================"
    echo ""
    
    check_prerequisites
    clean_build
    build_app
    prepare_app
    embed_provisioning_profiles
    sign_app
    verify_app
    install_app
    notarize_app
    create_dmg
    notarize_dmg
    create_release_summary
    
    # Final output
    DMG_PATH="$OUTPUT_DIR/GigEVirtualCamera.dmg"
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    
    echo ""
    echo "=========================================="
    print_success "🎉 Distribution build complete!"
    echo "=========================================="
    echo ""
    echo "📦 Distribution package:"
    echo "   $DMG_PATH ($DMG_SIZE)"
    echo ""
    echo "✅ Fully signed with Developer ID"
    echo "✅ Provisioning profiles embedded"
    echo "✅ App and DMG notarized"
    echo "✅ Ready for distribution"
    echo ""
    echo "📋 See release summary: $OUTPUT_DIR/release-summary.txt"
    echo ""
    
    # Open output directory
    open "$OUTPUT_DIR"
}

# Run main function
main