#!/bin/bash

# create_dmg.sh - Create a professional DMG for GigE Virtual Camera
# This script creates a properly formatted DMG with background image and layout

set -e

# Configuration
APP_PATH="${1:-/Applications/GigEVirtualCamera.app}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/build/distribution"
DMG_NAME="GigEVirtualCamera.dmg"
VOLUME_NAME="GigEVirtualCamera"
BACKGROUND_COLOR="#2c3e50"
IDENTITY="Developer ID Application: Luke  Chang (S368GH6KF7)"

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

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    print_error "App not found at: $APP_PATH"
    exit 1
fi

# Check if app is signed
if ! codesign -dvv "$APP_PATH" 2>&1 | grep -q "Developer ID Application"; then
    print_error "App is not signed with Developer ID certificate"
    echo "Please run ./Scripts/build_release.sh first to sign the app"
    exit 1
fi

print_status "Creating DMG for GigE Virtual Camera..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Remove existing DMG
rm -f "$OUTPUT_DIR/$DMG_NAME"

# Create temporary directory for DMG contents
DMG_TEMP="$OUTPUT_DIR/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
print_status "Copying app to DMG staging area..."
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create Applications symlink for drag-and-drop installation
print_status "Creating Applications symlink..."
ln -s /Applications "$DMG_TEMP/Applications"

# Copy the user-friendly README
print_status "Copying README for users..."
if [ -f "$PROJECT_ROOT/README_USER.md" ]; then
    cp "$PROJECT_ROOT/README_USER.md" "$DMG_TEMP/README.md"
else
    print_warning "README_USER.md not found, creating basic instructions..."
    cat > "$DMG_TEMP/README.txt" << EOF
GigE Virtual Camera Installation
==============================

1. Drag GigEVirtualCamera.app to the Applications folder
2. Open the app and grant necessary permissions when prompted
3. The virtual camera will appear in applications like Photo Booth, 
   QuickTime Player, Zoom, etc.

System Requirements:
- macOS 12.3 or later
- GigE Vision compatible camera (or use built-in test camera)

Note: On first launch, you may need to approve the Camera Extension 
in System Settings > Privacy & Security > Camera.
EOF
fi

# Copy the LICENSE file
print_status "Copying LICENSE file..."
if [ -f "$PROJECT_ROOT/LICENSE" ]; then
    cp "$PROJECT_ROOT/LICENSE" "$DMG_TEMP/LICENSE"
else
    print_warning "LICENSE file not found"
fi

# Get app version for DMG sizing
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))  # Add 50MB buffer

# Create initial DMG
print_status "Creating initial DMG (${DMG_SIZE}MB)..."
hdiutil create -srcfolder "$DMG_TEMP" \
               -volname "$VOLUME_NAME" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDRW \
               -size ${DMG_SIZE}m \
               "$OUTPUT_DIR/temp.dmg"

# Mount the DMG
print_status "Mounting DMG for customization..."
MOUNT_DIR="/Volumes/$VOLUME_NAME"
hdiutil attach -readwrite -noverify -noautoopen "$OUTPUT_DIR/temp.dmg"

# Wait for mount
sleep 2

# Customize the DMG appearance with AppleScript
print_status "Customizing DMG appearance..."
osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 920, 440}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set background color of viewOptions to {11264, 15872, 20480}
        
        -- Position items
        set position of item "GigEVirtualCamera.app" of container window to {130, 120}
        set position of item "Applications" of container window to {390, 120}
        try
            set position of item "README.md" of container window to {200, 250}
        on error
            try
                set position of item "README.txt" of container window to {200, 250}
            end try
        end try
        try
            set position of item "LICENSE" of container window to {320, 250}
        end try
        
        -- Update and close
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Sync filesystem
sync

# Unmount
print_status "Unmounting DMG..."
hdiutil detach "$MOUNT_DIR"

# Convert to compressed, read-only DMG
print_status "Converting to final DMG format..."
hdiutil convert "$OUTPUT_DIR/temp.dmg" \
               -format UDZO \
               -imagekey zlib-level=9 \
               -o "$OUTPUT_DIR/$DMG_NAME"

# Clean up
rm -f "$OUTPUT_DIR/temp.dmg"
rm -rf "$DMG_TEMP"

# Sign the DMG
print_status "Signing DMG..."
codesign --force --sign "$IDENTITY" "$OUTPUT_DIR/$DMG_NAME"

# Verify the signature
if codesign --verify --verbose "$OUTPUT_DIR/$DMG_NAME" 2>/dev/null; then
    print_success "DMG signature verified"
else
    print_warning "DMG signature verification failed"
fi

# Get final size
FINAL_SIZE=$(du -h "$OUTPUT_DIR/$DMG_NAME" | cut -f1)

print_success "DMG created successfully!"
echo ""
echo "📦 File: $OUTPUT_DIR/$DMG_NAME"
echo "📏 Size: $FINAL_SIZE"
echo ""
print_warning "IMPORTANT: This DMG is NOT notarized yet!"
echo ""
echo "Next steps:"
echo "1. Test the DMG locally: open $OUTPUT_DIR/$DMG_NAME"
echo "2. REQUIRED FOR DISTRIBUTION: Notarize the DMG:"
echo "   ./Scripts/notarize_dmg.sh $OUTPUT_DIR/$DMG_NAME"
echo "3. Only share the DMG AFTER notarization is complete"
echo ""
echo "The DMG includes:"
echo "• GigEVirtualCamera.app"
echo "• Applications folder shortcut for easy installation"
echo "• README.md with comprehensive user documentation"
echo "• LICENSE file (MIT License)"