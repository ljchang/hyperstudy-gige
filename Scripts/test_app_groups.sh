#!/bin/bash

echo "=== Testing App Groups Communication ==="
echo ""

APP_GROUP="group.S368GH6KF7.com.lukechang.GigEVirtualCamera"
CONTAINER="$HOME/Library/Group Containers/$APP_GROUP"

echo "1. App Group Container Path:"
echo "   $CONTAINER"
echo ""

echo "2. Container Contents:"
if [ -d "$CONTAINER" ]; then
    ls -la "$CONTAINER" | head -10
else
    echo "   Container does not exist!"
fi
echo ""

echo "3. Testing write access (as app would):"
# Write test data
defaults write "$CONTAINER/Library/Preferences/$APP_GROUP.plist" TestKey "TestValue at $(date)"
if [ $? -eq 0 ]; then
    echo "   ✓ Write successful"
else
    echo "   ✗ Write failed"
fi

echo ""
echo "4. Testing read access:"
VALUE=$(defaults read "$CONTAINER/Library/Preferences/$APP_GROUP.plist" TestKey 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "   ✓ Read successful: $VALUE"
else
    echo "   ✗ Read failed"
fi

echo ""
echo "5. Simulating extension signal:"
# Simulate what the extension would write
defaults write "$CONTAINER/Library/Preferences/$APP_GROUP.plist" StreamState '{streamActive = 1; timestamp = '"$(date +%s)"'; pid = 12345;}'

echo ""
echo "6. Reading simulated signal:"
defaults read "$CONTAINER/Library/Preferences/$APP_GROUP.plist" StreamState

echo ""
echo "7. Cleaning up test data:"
defaults delete "$CONTAINER/Library/Preferences/$APP_GROUP.plist" TestKey 2>/dev/null
echo "   Done"