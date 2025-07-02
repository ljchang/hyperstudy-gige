#!/bin/bash

echo "=== Monitoring Extension Frame Processing ==="
echo ""

# Check current frame index
echo "Current frame index in shared data:"
plutil -p "$HOME/Library/Group Containers/group.S368GH6KF7.com.lukechang.GigEVirtualCamera/Library/Preferences/group.S368GH6KF7.com.lukechang.GigEVirtualCamera.plist" | grep -i frameindex

echo ""
echo "Monitoring extension logs..."
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --info --style compact | grep -E "(Checking frame|New frame|Stream started|Stream stopped|No new frame|Frame #)"