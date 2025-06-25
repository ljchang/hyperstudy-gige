#!/bin/bash
# Create Xcode project for GigE Virtual Camera

echo "Creating Xcode project..."

cd "$(dirname "$0")/.."

# Create the project using xcodegen or manual creation
cat > project.yml << EOF
name: GigEVirtualCamera
options:
  bundleIdPrefix: com.lukechang
  deploymentTarget:
    macOS: "12.3"
  developmentLanguage: en
  
settings:
  DEVELOPMENT_TEAM: S368GH6KF7
  
targets:
  GigEVirtualCamera:
    type: application
    platform: macOS
    sources:
      - GigECameraApp
      - Shared
    dependencies:
      - target: GigECameraExtension
        embed: true
        codeSign: true
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.lukechang.GigEVirtualCamera
      INFOPLIST_FILE: GigECameraApp/Info.plist
      CODE_SIGN_ENTITLEMENTS: GigECameraApp/GigECamera.entitlements
      SWIFT_VERSION: 5.0
      MARKETING_VERSION: 1.0
      CURRENT_PROJECT_VERSION: 1
    preBuildScripts:
      - script: |
          if [ -d "\${SRCROOT}/Scripts" ]; then
            chmod +x "\${SRCROOT}/Scripts/*.sh"
          fi
        name: Make Scripts Executable
    postBuildScripts:
      - script: |
          "\${SRCROOT}/Scripts/bundle_libraries.sh"
        name: Bundle Aravis Libraries
        inputFiles:
          - /opt/homebrew/lib/libaravis-0.8.dylib
        outputFiles:
          - \${BUILT_PRODUCTS_DIR}/\${FRAMEWORKS_FOLDER_PATH}/libaravis-0.8.dylib
          
  GigECameraExtension:
    type: system-extension
    platform: macOS
    sources:
      - GigECameraExtension
      - Shared
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.lukechang.GigEVirtualCamera.Extension
      INFOPLIST_FILE: GigECameraExtension/Info.plist
      CODE_SIGN_ENTITLEMENTS: GigECameraExtension/GigECameraExtension.entitlements
      SWIFT_VERSION: 5.0
      MARKETING_VERSION: 1.0
      CURRENT_PROJECT_VERSION: 1
EOF

echo "Project configuration created!"
echo ""
echo "To generate Xcode project:"
echo "1. Install xcodegen: brew install xcodegen"
echo "2. Run: xcodegen generate"
echo ""
echo "Or create manually in Xcode with:"
echo "- macOS App target: GigEVirtualCamera"
echo "- System Extension target: GigECameraExtension"
echo "- Team ID: S368GH6KF7"