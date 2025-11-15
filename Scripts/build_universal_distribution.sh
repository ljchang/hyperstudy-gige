#!/bin/bash

# build_universal_distribution.sh - Build for maximum compatibility
# Ensures the app works on any Apple Silicon Mac

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/build/distribution"

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
echo "🚀 Building GigE Virtual Camera for Universal Distribution"
echo "========================================================"
echo ""

# Step 1: Clean and build with generic destination
print_status "Step 1: Building for Any Mac (arm64)..."
cd "$PROJECT_ROOT"

# Clean any existing builds
rm -rf build/Release
rm -rf /Applications/GigEVirtualCamera.app

# Build for generic macOS (not specific to this Mac)
xcodebuild -project GigEVirtualCamera.xcodeproj \
    -scheme GigEVirtualCamera \
    -configuration Release \
    -destination "generic/platform=macOS" \
    ARCHS="arm64" \
    ONLY_ACTIVE_ARCH=NO \
    MACOSX_DEPLOYMENT_TARGET="12.3" \
    clean build

print_success "Build completed"

# Step 2: Verify the app was installed
if [ ! -d "/Applications/GigEVirtualCamera.app" ]; then
    print_error "App not found in /Applications"
    exit 1
fi

# Step 3: Re-sign with distribution entitlements
print_status "Step 2: Re-signing for distribution..."
"$SCRIPT_DIR/resign_for_distribution.sh"

# Step 4: Clear any extended attributes
print_status "Step 3: Clearing extended attributes..."
xattr -cr /Applications/GigEVirtualCamera.app 2>/dev/null || true
print_success "Extended attributes cleared"

# Step 5: Notarize the app
print_status "Step 4: Notarizing the application..."
"$SCRIPT_DIR/notarize.sh" /Applications/GigEVirtualCamera.app

# Step 6: Create DMG
print_status "Step 5: Creating distribution DMG..."
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/GigEVirtualCamera.dmg"

# Create a clean DMG
"$SCRIPT_DIR/create_dmg.sh" /Applications/GigEVirtualCamera.app

# Step 7: Sign the DMG
print_status "Step 6: Signing the DMG..."
codesign --force --sign "Developer ID Application" \
    "$OUTPUT_DIR/GigEVirtualCamera.dmg"
print_success "DMG signed"

# Step 8: Notarize the DMG
print_status "Step 7: Notarizing the DMG..."
NOTARIZE_OUTPUT=$(xcrun notarytool submit "$OUTPUT_DIR/GigEVirtualCamera.dmg" \
    --keychain-profile "GigE-Notarization" \
    --wait 2>&1)

if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
    print_success "DMG notarization accepted"
    
    # Staple the ticket
    if xcrun stapler staple "$OUTPUT_DIR/GigEVirtualCamera.dmg"; then
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

# Step 9: Final verification
print_status "Step 8: Final verification..."
if spctl -a -vvv "$OUTPUT_DIR/GigEVirtualCamera.dmg" 2>&1 | grep -q "source=Notarized Developer ID"; then
    print_success "DMG verified as notarized"
else
    print_error "DMG verification failed"
    exit 1
fi

# Get final details
DMG_SIZE=$(du -h "$OUTPUT_DIR/GigEVirtualCamera.dmg" | cut -f1)
APP_VERSION=$(defaults read /Applications/GigEVirtualCamera.app/Contents/Info.plist CFBundleShortVersionString)

echo ""
print_success "🎉 Universal distribution build complete!"
echo ""
echo "📦 Distribution DMG:"
echo "   Location: $OUTPUT_DIR/GigEVirtualCamera.dmg"
echo "   Size: $DMG_SIZE"
echo "   Version: $APP_VERSION"
echo ""
echo "✅ Built for: Any Mac with Apple Silicon"
echo "✅ Minimum OS: macOS 12.3+"
echo "✅ Fully notarized and ready for distribution"
echo ""
echo "To test on another Mac:"
echo "1. Copy the DMG to the target Mac"
echo "2. Double-click to mount"
echo "3. Drag to Applications"
echo "4. The app should open without any warnings"
echo ""
echo "If issues persist, run this on the target Mac:"
echo "  ./Scripts/diagnose_distribution.sh"
echo ""