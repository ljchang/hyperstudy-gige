#!/bin/bash

echo "🔍 Debugging GigE Camera Extension..."
echo ""

# Check if app is running
echo "1️⃣ Checking app process:"
ps aux | grep -i "GigEVirtualCamera" | grep -v grep || echo "App not running"
echo ""

# Check if extension process exists
echo "2️⃣ Checking extension process:"
ps aux | grep -i "GigECameraExtension" | grep -v grep || echo "Extension process not found"
echo ""

# Check system extension status
echo "3️⃣ System extensions status:"
systemextensionsctl list | grep -i gige || echo "No GigE system extension found"
echo ""

# Check for CMIO plugins
echo "4️⃣ Checking CMIO in IORegistry:"
ioreg -l -w0 | grep -i "cmio" | grep -i "gige" || echo "No GigE CMIO device in IORegistry"
echo ""

# Check launchd for camera extension
echo "5️⃣ Checking launchd for camera services:"
launchctl list | grep -i camera | head -5
echo ""

# Check Console for recent errors
echo "6️⃣ Recent camera-related errors (last 30 seconds):"
log show --predicate 'subsystem CONTAINS "cmio" OR process CONTAINS "camera"' --last 30s --style compact 2>/dev/null | grep -i "gige\|error" | tail -10 || echo "No recent camera errors"
echo ""

# Check if extension binary exists and is executable
echo "7️⃣ Extension binary check:"
EXTENSION_PATH="/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension/Contents/MacOS/GigECameraExtension"
if [ -f "$EXTENSION_PATH" ]; then
    echo "✅ Extension binary exists"
    file "$EXTENSION_PATH"
    ls -la "$EXTENSION_PATH"
else
    echo "❌ Extension binary not found at expected path"
fi
echo ""

# Check code signing
echo "8️⃣ Code signing status:"
codesign -dv /Applications/GigEVirtualCamera.app 2>&1 | grep -E "Identifier|TeamIdentifier|Format"
echo ""
codesign -dv /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension 2>&1 | grep -E "Identifier|TeamIdentifier|Format"
echo ""

# Suggest next steps
echo "💡 Troubleshooting suggestions:"
echo "1. Try restarting the camera daemon: sudo killall -9 appleh13camerad"
echo "2. Check Console.app for detailed error messages"
echo "3. Ensure app is properly signed with Developer ID certificate"
echo "4. Try running: systemextensionsctl reset"