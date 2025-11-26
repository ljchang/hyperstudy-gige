#!/bin/bash

# notarize.sh - Automated notarization script for GigE Virtual Camera
# This script handles the complete notarization process including:
# - Creating a properly signed archive
# - Submitting to Apple for notarization
# - Waiting for completion
# - Stapling the ticket
# - Verifying the result

set -e

# Configuration
APP_PATH="${1:-/Applications/GigEVirtualCamera.app}"
PROFILE_NAME="${NOTARIZATION_PROFILE:-GigE-Notarization}"
OUTPUT_DIR="$(pwd)/build/notarization"
ARCHIVE_NAME="GigEVirtualCamera.zip"
DMG_NAME="GigEVirtualCamera.dmg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

check_requirements() {
    print_status "Checking requirements..."
    
    # Check if app exists
    if [ ! -d "$APP_PATH" ]; then
        print_error "App not found at: $APP_PATH"
        exit 1
    fi
    
    # Check if notarytool is available
    if ! command -v xcrun &> /dev/null; then
        print_error "xcrun not found. Please install Xcode command line tools."
        exit 1
    fi
    
    # Check if credentials are stored by trying to use them
    if ! xcrun notarytool history --keychain-profile "$PROFILE_NAME" &> /dev/null; then
        print_warning "Notarization credentials not found or invalid."
        echo ""
        echo "Please run the following command to store your credentials:"
        echo ""
        echo "  xcrun notarytool store-credentials \"$PROFILE_NAME\" \\"
        echo "      --apple-id \"your-apple-id@example.com\" \\"
        echo "      --team-id \"YOUR_TEAM_ID_HERE\" \\"
        echo "      --password \"your-app-specific-password\""
        echo ""
        echo "To create an app-specific password:"
        echo "1. Go to https://appleid.apple.com/account/manage"
        echo "2. Sign in and go to Security > App-Specific Passwords"
        echo "3. Click Generate Password and save it securely"
        echo ""
        exit 1
    fi
    
    print_success "All requirements met"
}

verify_signing() {
    print_status "Verifying code signing..."
    
    # Check main app
    if ! codesign -dvv "$APP_PATH" 2>&1 | grep -q "Developer ID Application"; then
        print_error "App is not signed with Developer ID certificate"
        echo "Current signing:"
        codesign -dvv "$APP_PATH" 2>&1 | grep "Authority"
        exit 1
    fi
    
    # Check if hardened runtime is enabled
    if ! codesign -dv "$APP_PATH" 2>&1 | grep -q "flags=0x10000(runtime)"; then
        print_warning "Hardened runtime not enabled. This is required for notarization."
        exit 1
    fi
    
    # Check System Extension
    EXTENSION_PATH="$APP_PATH/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
    if [ -d "$EXTENSION_PATH" ]; then
        print_status "Verifying System Extension signature..."
        if ! codesign -dvv "$EXTENSION_PATH" 2>&1 | grep -q "Developer ID Application"; then
            print_error "System Extension is not signed with Developer ID certificate"
            exit 1
        fi
        
        # Verify extension has proper entitlements
        if codesign -d --entitlements - "$APP_PATH" 2>&1 | grep -q "com.apple.developer.system-extension.install"; then
            print_success "System Extension install entitlement present"
        else
            print_error "Missing com.apple.developer.system-extension.install entitlement"
            exit 1
        fi
    fi
    
    # Verify signatures (not using --deep as we check components individually)
    if codesign --verify --strict "$APP_PATH" 2>&1; then
        print_success "App signature valid"
    else
        print_error "App signature verification failed"
        exit 1
    fi
    
    if [ -d "$EXTENSION_PATH" ] && codesign --verify --strict "$EXTENSION_PATH" 2>&1; then
        print_success "System Extension signature valid"
    fi
}

create_archive() {
    print_status "Creating archive for notarization..."
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Remove old archive if it exists
    rm -f "$OUTPUT_DIR/$ARCHIVE_NAME"
    
    # Create zip using ditto (preserves macOS metadata)
    if ditto -c -k --keepParent "$APP_PATH" "$OUTPUT_DIR/$ARCHIVE_NAME"; then
        print_success "Archive created: $OUTPUT_DIR/$ARCHIVE_NAME"
        echo "  Size: $(du -h "$OUTPUT_DIR/$ARCHIVE_NAME" | cut -f1)"
    else
        print_error "Failed to create archive"
        exit 1
    fi
}

submit_for_notarization() {
    print_status "Submitting for notarization..."
    echo "  This usually takes 5-15 minutes..."
    echo ""
    
    # Submit and capture output
    SUBMIT_OUTPUT=$(xcrun notarytool submit "$OUTPUT_DIR/$ARCHIVE_NAME" \
        --keychain-profile "$PROFILE_NAME" \
        --wait \
        --output-format json 2>&1)
    
    # Check if submission was successful
    if echo "$SUBMIT_OUTPUT" | grep -q '"status":"Accepted"'; then
        SUBMISSION_ID=$(echo "$SUBMIT_OUTPUT" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 | head -1)
        print_success "Notarization successful!"
        echo "  Submission ID: $SUBMISSION_ID"
        return 0
    elif echo "$SUBMIT_OUTPUT" | grep -q '"status":"Invalid"'; then
        print_error "Notarization failed!"
        SUBMISSION_ID=$(echo "$SUBMIT_OUTPUT" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 | head -1)
        
        # Try to get the log
        print_status "Fetching detailed error log..."
        xcrun notarytool log "$SUBMISSION_ID" \
            --keychain-profile "$PROFILE_NAME" \
            "$OUTPUT_DIR/notarization-log.json" 2>/dev/null || true
        
        if [ -f "$OUTPUT_DIR/notarization-log.json" ]; then
            echo ""
            echo "Issues found:"
            cat "$OUTPUT_DIR/notarization-log.json" | grep -A5 '"severity":"error"' || \
                echo "Check $OUTPUT_DIR/notarization-log.json for details"
        fi
        exit 1
    else
        print_error "Unexpected response from notarization service"
        echo "$SUBMIT_OUTPUT"
        exit 1
    fi
}

staple_ticket() {
    print_status "Stapling notarization ticket to app..."
    
    if xcrun stapler staple "$APP_PATH" 2>&1; then
        print_success "Ticket stapled successfully"
    else
        print_error "Failed to staple ticket"
        echo "The app is notarized but requires internet for first launch"
        return 1
    fi
}

verify_notarization() {
    print_status "Verifying notarization..."
    
    # Check with spctl
    SPCTL_OUTPUT=$(spctl -a -vvv "$APP_PATH" 2>&1)
    
    if echo "$SPCTL_OUTPUT" | grep -q "source=Notarized Developer ID"; then
        print_success "App is properly notarized and ready for distribution!"
        echo "$SPCTL_OUTPUT" | grep "source="
    else
        print_warning "Notarization verification shows:"
        echo "$SPCTL_OUTPUT"
    fi
    
    # Check System Extension specifically
    EXTENSION_PATH="$APP_PATH/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension"
    if [ -d "$EXTENSION_PATH" ]; then
        echo ""
        print_status "Checking System Extension notarization..."
        SPCTL_EXT_OUTPUT=$(spctl -a -vvv -t sysx "$EXTENSION_PATH" 2>&1)
        
        if echo "$SPCTL_EXT_OUTPUT" | grep -q "accepted"; then
            print_success "System Extension is properly notarized"
        else
            print_warning "System Extension verification shows:"
            echo "$SPCTL_EXT_OUTPUT"
        fi
    fi
    
    # Also check with stapler
    echo ""
    print_status "Checking stapled ticket..."
    if xcrun stapler validate "$APP_PATH" 2>&1 | grep -q "The validate action worked"; then
        print_success "Stapled ticket is valid"
    else
        print_warning "Stapled ticket validation failed"
    fi
}

create_dmg() {
    print_status "Creating DMG for distribution (optional)..."
    
    echo "Would you like to create a DMG for easier distribution? (y/n)"
    read -r response
    
    if [[ "$response" == "y" ]]; then
        # Create a temporary directory for DMG contents
        DMG_TEMP="$OUTPUT_DIR/dmg-temp"
        rm -rf "$DMG_TEMP"
        mkdir -p "$DMG_TEMP"
        
        # Copy app to temp directory
        cp -R "$APP_PATH" "$DMG_TEMP/"
        
        # Create DMG
        hdiutil create -volname "GigE Virtual Camera" \
                      -srcfolder "$DMG_TEMP" \
                      -ov \
                      -format UDZO \
                      "$OUTPUT_DIR/$DMG_NAME"
        
        # Sign the DMG
        IDENTITY="${CODE_SIGN_IDENTITY:-Developer ID Application}"
        codesign --force --sign "$IDENTITY" \
                 "$OUTPUT_DIR/$DMG_NAME"
        
        # Notarize the DMG too
        print_status "Notarizing DMG..."
        xcrun notarytool submit "$OUTPUT_DIR/$DMG_NAME" \
            --keychain-profile "$PROFILE_NAME" \
            --wait
        
        # Staple to DMG
        xcrun stapler staple "$OUTPUT_DIR/$DMG_NAME"
        
        # Clean up
        rm -rf "$DMG_TEMP"
        
        print_success "DMG created: $OUTPUT_DIR/$DMG_NAME"
    fi
}

# Main execution
main() {
    echo ""
    echo "🚀 GigE Virtual Camera Notarization Tool"
    echo "========================================"
    echo ""
    
    check_requirements
    verify_signing
    create_archive
    submit_for_notarization
    staple_ticket
    verify_notarization
    create_dmg
    
    # Clean up archive
    rm -f "$OUTPUT_DIR/$ARCHIVE_NAME"
    
    echo ""
    print_success "🎉 Notarization complete!"
    echo ""
    echo "The app at $APP_PATH is now notarized and ready for distribution."
    echo "Users can download and run it without Gatekeeper warnings."
    echo ""
    echo "Next steps:"
    echo "1. Test the app by running: open $APP_PATH"
    echo "2. Check if the virtual camera appears in Photo Booth or QuickTime"
    echo "3. Distribute the app or DMG to users"
    echo ""
}

# Run main function
main "$@"