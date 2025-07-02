#!/bin/bash

echo "=== Monitoring Live Frame Flow ==="
echo "Press Ctrl+C to stop"
echo ""

# Check current state
echo "Current IOSurface IDs:"
plutil -p "$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist" | grep -A 5 IOSurfaceIDs

echo ""
echo "Monitoring frame activity..."
echo ""

# Monitor logs
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" OR subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --info --style compact | grep -E "(IOSurface|Wrote frame|Frame #|Discovered|writeFrame|Failed to lookup|readSurfaceIDs)"