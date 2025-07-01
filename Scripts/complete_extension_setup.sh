#!/bin/bash

echo "=== Extension Setup Complete! ==="
echo
echo "✅ Extension is installed and activated!"
echo
echo "To complete the setup:"
echo
echo "1. Go to System Settings > General > Login Items & Extensions > Camera Extensions"
echo "2. Enable 'GigE Camera Extension' if not already enabled"
echo
echo "3. Test the virtual camera:"
echo "   - Open QuickTime Player" 
echo "   - File → New Movie Recording"
echo "   - Click the dropdown arrow next to the record button"
echo "   - Select 'GigE Virtual Camera'"
echo
echo "4. If the camera doesn't appear immediately:"
echo "   - Quit and restart QuickTime"
echo "   - Or restart your Mac"
echo
echo "Current extension status:"
systemextensionsctl list | grep -A1 "com.lukechang.GigEVirtualCamera.Extension"