#!/bin/bash

echo "=== Camera Extension Diagnostic ==="
echo

# 1. Check if running in Xcode
echo "1. Checking if running from Xcode build..."
if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
    RECENT_BUILD=$(find "$HOME/Library/Developer/Xcode/DerivedData" -name "GigEVirtualCamera.app" -type d -mtime -1 | head -1)
    if [ -n "$RECENT_BUILD" ]; then
        echo "   Found recent Xcode build: $RECENT_BUILD"
        echo "   Note: Extensions from Xcode builds may not appear in other apps"
    fi
fi

# 2. Check installed app
echo -e "\n2. Checking installed app..."
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    echo "   ✓ App installed"
    
    # Check if extension exists
    if [ -d "/Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex" ]; then
        echo "   ✓ Extension bundle present"
        
        # Check bundle ID
        BUNDLE_ID=$(defaults read /Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex/Contents/Info.plist CFBundleIdentifier 2>/dev/null)
        echo "   Bundle ID: $BUNDLE_ID"
        
        # Check mach service name
        MACH_SERVICE=$(plutil -extract CMIOExtension.CMIOExtensionMachServiceName raw /Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex/Contents/Info.plist 2>/dev/null)
        echo "   Mach Service: $MACH_SERVICE"
    fi
fi

# 3. Check Camera Privacy Settings
echo -e "\n3. Checking camera privacy database..."
# This requires admin access, so we'll just guide the user
echo "   To check manually:"
echo "   - Open System Settings > Privacy & Security > Camera"
echo "   - Look for 'GigE Virtual Camera'"

# 4. Try to list available cameras using AVFoundation
echo -e "\n4. Testing camera availability..."
cat > /tmp/test_camera.swift << 'EOF'
import AVFoundation

let devices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.externalUnknown, .builtInWideAngleCamera],
    mediaType: .video,
    position: .unspecified
).devices

print("Available cameras:")
for device in devices {
    print("  - \(device.localizedName) [\(device.uniqueID)]")
}

if devices.contains(where: { $0.localizedName.contains("GigE") }) {
    print("\n✓ GigE Virtual Camera found!")
} else {
    print("\n✗ GigE Virtual Camera not found")
}
EOF

swift /tmp/test_camera.swift 2>/dev/null || echo "   Unable to test camera availability"

# 5. Check for common issues
echo -e "\n5. Common Issues:"

# Check if app was launched
ps aux | grep -q "[G]igEVirtualCamera" && echo "   ✓ App is running" || echo "   ✗ App is not running - Launch the app first"

# Check permissions
echo -e "\n6. Required Steps:"
echo "   1. Launch /Applications/GigEVirtualCamera.app"
echo "   2. Click 'Install Extension' button in the app"
echo "   3. Grant camera permissions when prompted"
echo "   4. Quit and restart apps that use cameras (Zoom, FaceTime, etc.)"
echo "   5. Select 'GigE Virtual Camera' from camera list"

echo -e "\n7. Alternative Test:"
echo "   Try in Photo Booth app first - it's the most reliable for testing"
echo "   Open Photo Booth and check the Camera menu"

echo -e "\n=== End Diagnostic ==="