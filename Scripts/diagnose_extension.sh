#!/bin/bash

echo "=== System Extension Diagnostic Tool ==="
echo

# Check developer mode
echo "1. Developer Mode Status:"
systemextensionsctl developer
echo

# List all extensions
echo "2. Current System Extensions:"
systemextensionsctl list
echo

# Check for pending approvals
echo "3. Checking for pending approvals in database:"
sudo sqlite3 /var/db/SystemExtensionManagement/KnownExtensions.db "SELECT * FROM extension_policies;" 2>/dev/null || echo "Unable to access database (need sudo)"
echo

# Check app signature
echo "4. App Signature Check:"
codesign -dvv /Applications/GigEVirtualCamera.app 2>&1 | grep -E "(Signature|Authority|TeamIdentifier|Identifier)"
echo

# Check extension signature
echo "5. Extension Signature Check:"
if [ -d "/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension" ]; then
    codesign -dvv /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension 2>&1 | grep -E "(Signature|Authority|TeamIdentifier|Identifier)"
else
    echo "Extension bundle not found"
fi
echo

# Check entitlements
echo "6. App Entitlements:"
codesign -d --entitlements - /Applications/GigEVirtualCamera.app 2>&1 | grep -A30 "<?xml" | grep -E "(system-extension|sandbox|application-groups)"
echo

# Recent sysextd logs
echo "7. Recent System Extension Daemon Activity:"
log show --process sysextd --last 5m 2>&1 | grep -i "com.lukechang" | tail -10 || echo "No recent activity found"
echo

# Check for approval prompts
echo "8. Extension Approval Status:"
echo "Run this command to check for pending approvals:"
echo "defaults read /Library/Preferences/com.apple.system-extension-policy.plist"
echo

echo "=== Troubleshooting Tips ==="
echo "1. If extension not loading, check System Settings > Privacy & Security"
echo "2. Try: sudo systemextensionsctl uninstall S368GH6KF7 com.lukechang.GigEVirtualCamera.Extension"
echo "3. Then reinstall by clicking button in app"
echo "4. Check Console.app and filter by 'sysextd' for detailed errors"