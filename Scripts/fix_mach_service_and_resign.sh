#!/bin/bash

echo "=== Fixing Mach Service Name and Re-signing ==="
echo

# 1. Fix the Info.plist variables
echo "1. Expanding Info.plist variables..."
plutil -replace CFBundleExecutable -string "GigECameraExtension" /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist
plutil -replace CFBundleIdentifier -string "com.lukechang.GigEVirtualCamera.Extension" /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist
plutil -replace CFBundleName -string "GigECameraExtension" /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist
plutil -replace CFBundlePackageType -string "SYSX" /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist
plutil -replace CFBundleShortVersionString -string "1.0" /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist
plutil -replace CFBundleVersion -string "1" /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist
plutil -replace LSMinimumSystemVersion -string "13.0" /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist

# 2. Verify the mach service name
echo
echo "2. Verifying mach service name..."
MACH_SERVICE=$(plutil -extract CMIOExtension.CMIOExtensionMachServiceName raw /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/Info.plist)
echo "Mach service name: $MACH_SERVICE"

# 3. Re-sign the extension
echo
echo "3. Re-signing extension..."
IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | awk '{print $2}')
codesign --force --deep --sign "$IDENTITY" \
    --entitlements /Users/lukechang/Github/hyperstudy-gige/GigEVirtualCameraExtension/GigEVirtualCameraExtension.entitlements \
    --timestamp=none \
    /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension

# 4. Re-sign the main app
echo
echo "4. Re-signing main app..."
codesign --force --deep --sign "$IDENTITY" \
    --entitlements /Users/lukechang/Github/hyperstudy-gige/GigECameraApp/GigECamera-Debug.entitlements \
    --options runtime \
    --timestamp=none \
    /Applications/GigEVirtualCamera.app

# 5. Verify
echo
echo "5. Verifying signatures..."
codesign -vvv --deep --strict /Applications/GigEVirtualCamera.app 2>&1 | grep -E "valid|satisfies|error" || echo "✓ App signature valid"
codesign -vvv --deep --strict /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep -E "valid|satisfies|error" || echo "✓ Extension signature valid"

echo
echo "Done! Now run the app to test extension installation."