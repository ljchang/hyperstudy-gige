#!/bin/bash

echo "=== Activating Camera Extension ==="
echo

echo "1. Current extension state:"
systemextensionsctl list | grep -A1 "GigE"

echo
echo "2. Killing camera extension manager to force refresh..."
echo "This requires sudo permission:"
echo
echo "Run: sudo killall -9 cmioextensionmanagerd"
echo

echo "3. Alternative: Open System Settings directly to Camera Extensions:"
echo "Run: open x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
echo

echo "4. If still not visible, try:"
echo "   a) Restart your Mac"
echo "   b) Run: sudo systemextensionsctl reset"
echo "   c) Reinstall the app"
echo

echo "5. Check Console.app for any errors:"
echo "   - Open Console.app"
echo "   - Search for 'GigEVirtualCamera' or 'cmioextension'"