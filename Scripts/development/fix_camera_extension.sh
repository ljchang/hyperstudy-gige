#!/bin/bash

# Fix Camera Extension Registration Script

echo "=== GigE Virtual Camera Extension Fix ==="
echo

# Step 1: Check current status
echo "1. Checking current extension status..."
pluginkit -vvvv -m -p com.apple.cmio-camera-extension

# Step 2: Uninstall old app if exists
echo -e "\n2. Removing old app installation..."
if [ -d "/Applications/GigEVirtualCamera.app" ]; then
    sudo rm -rf /Applications/GigEVirtualCamera.app
    echo "   Removed old app"
else
    echo "   No existing app found"
fi

# Step 3: Remove extension from pluginkit cache
echo -e "\n3. Cleaning extension cache..."
pluginkit -r /Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex 2>/dev/null

# Step 4: Kill relevant processes
echo -e "\n4. Killing camera processes..."
killall -9 GigECameraExtension 2>/dev/null
killall -9 cmiodalassistants 2>/dev/null

# Step 5: Build instructions
echo -e "\n5. Build Instructions:"
echo "   Since the com.apple.private.cmio-camera-extension entitlement requires special"
echo "   approval from Apple, you have two options:"
echo
echo "   Option A: Use Development Build (Recommended for testing)"
echo "   --------------------------------------------------------"
echo "   1. Open GigEVirtualCamera.xcodeproj in Xcode"
echo "   2. Select your development team"
echo "   3. For the Extension target:"
echo "      - Remove 'com.apple.private.cmio-camera-extension' from entitlements"
echo "      - Use automatic signing"
echo "   4. Build and run the app"
echo "   5. When prompted, allow the system extension"
echo
echo "   Option B: Apply for Camera Extension Entitlement"
echo "   ------------------------------------------------"
echo "   1. Go to https://developer.apple.com/contact/request/"
echo "   2. Request the 'Camera Extension' entitlement"
echo "   3. Once approved, regenerate your provisioning profiles"
echo
echo "   For now, let's proceed with Option A..."

# Step 6: Create a modified entitlements file without the private entitlement
echo -e "\n6. Creating development entitlements..."
cat > /Users/lukechang/Github/hyperstudy-gige/macos/GigECameraExtension/GigECameraExtension-Dev.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.lukechang.gigecamera</string>
    </array>
</dict>
</plist>
EOF

echo "   Created GigECameraExtension-Dev.entitlements"

# Step 7: Build with development entitlements
echo -e "\n7. Building with development configuration..."
cd /Users/lukechang/Github/hyperstudy-gige/macos

# First, let's try building with automatic signing
xcodebuild -scheme GigEVirtualCamera \
    -configuration Debug \
    clean build \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=S368GH6KF7 \
    CODE_SIGN_ENTITLEMENTS_GigECameraExtension=GigECameraExtension/GigECameraExtension-Dev.entitlements \
    PRODUCT_BUNDLE_IDENTIFIER_GigECameraExtension=com.lukechang.GigEVirtualCamera.Extension

if [ $? -eq 0 ]; then
    echo -e "\n✅ Build succeeded!"
    
    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "GigEVirtualCamera.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        echo -e "\n8. Installing app..."
        sudo cp -R "$APP_PATH" /Applications/
        
        echo -e "\n9. Registering extension..."
        pluginkit -a /Applications/GigEVirtualCamera.app/Contents/PlugIns/GigECameraExtension.appex
        
        echo -e "\n10. Verifying registration..."
        pluginkit -vvvv -m -p com.apple.cmio-camera-extension | grep -i gige
        
        echo -e "\n✅ Installation complete!"
        echo -e "\nNow:"
        echo "1. Open /Applications/GigEVirtualCamera.app"
        echo "2. Follow any system prompts to allow the extension"
        echo "3. Go to System Settings > Privacy & Security > Camera"
        echo "4. Make sure GigE Virtual Camera is allowed"
        echo "5. Restart any apps that need to use the camera"
    else
        echo "❌ Could not find built app"
    fi
else
    echo -e "\n❌ Build failed. Please open the project in Xcode and:"
    echo "1. Update the signing settings"
    echo "2. Use the GigECameraExtension-Dev.entitlements file for the extension"
    echo "3. Build and run from Xcode"
fi

echo -e "\n=== Done ==="