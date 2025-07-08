#!/bin/bash

# notarize_dmg.sh - Notarize an existing DMG file
# This script notarizes a DMG that was already created and signed

set -e

# Configuration
DMG_PATH="${1:-build/distribution/GigEVirtualCamera.dmg}"
PROFILE_NAME="${NOTARIZATION_PROFILE:-GigE-Notarization}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Check if DMG exists
if [ ! -f "$DMG_PATH" ]; then
    print_error "DMG not found at: $DMG_PATH"
    exit 1
fi

# Check if DMG is signed
if ! codesign -dvv "$DMG_PATH" 2>&1 | grep -q "Developer ID Application"; then
    print_error "DMG is not signed with Developer ID certificate"
    exit 1
fi

print_status "Notarizing DMG: $DMG_PATH"

# Submit for notarization
print_status "Submitting DMG for notarization..."
SUBMIT_OUTPUT=$(xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$PROFILE_NAME" \
    --wait \
    --output-format json 2>&1)

# Check if submission was successful
if echo "$SUBMIT_OUTPUT" | grep -q '"status":"Accepted"'; then
    SUBMISSION_ID=$(echo "$SUBMIT_OUTPUT" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 | head -1)
    print_success "DMG notarization successful!"
    echo "  Submission ID: $SUBMISSION_ID"
else
    print_error "DMG notarization failed!"
    echo "$SUBMIT_OUTPUT"
    exit 1
fi

# Staple the ticket to the DMG
print_status "Stapling notarization ticket to DMG..."
if xcrun stapler staple "$DMG_PATH" 2>&1; then
    print_success "Ticket stapled successfully"
else
    print_error "Failed to staple ticket to DMG"
    exit 1
fi

# Verify the notarization
print_status "Verifying DMG notarization..."
if spctl -a -vvv -t install "$DMG_PATH" 2>&1 | grep -q "source=Notarized Developer ID"; then
    print_success "DMG is properly notarized and ready for distribution!"
else
    print_error "DMG notarization verification failed"
    spctl -a -vvv -t install "$DMG_PATH"
    exit 1
fi

print_success "🎉 DMG notarization complete!"
echo ""
echo "The DMG at $DMG_PATH is now fully notarized."
echo "Users can download and open it without Gatekeeper warnings."