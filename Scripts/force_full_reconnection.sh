#!/bin/bash

echo "=== Force Full Sink Stream Reconnection ==="
echo ""

# Step 1: Kill Photo Booth to stop the stream
echo "1. Stopping Photo Booth..."
pkill -x "Photo Booth" 2>/dev/null
sleep 2

# Step 2: Send disconnect signal to app
echo "2. Sending disconnect signal to app..."
cat > /tmp/disconnect_sink.swift << 'EOF'
import Foundation

// Send notification to disconnect frame sender
DistributedNotificationCenter.default().post(
    name: NSNotification.Name("DisconnectFrameSender"),
    object: nil
)
print("Sent disconnect signal")
EOF
swift /tmp/disconnect_sink.swift

sleep 2

# Step 3: Restart Photo Booth
echo "3. Restarting Photo Booth..."
open -a "Photo Booth"
sleep 3

# Step 4: Wait for Photo Booth to start streaming
echo "4. Waiting for Photo Booth to select camera and start streaming..."
echo "   Please ensure 'GigE Virtual Camera' is selected in Photo Booth"
sleep 5

# Step 5: Trigger reconnection
echo "5. Triggering sink stream reconnection..."
cat > /tmp/reconnect_sink.swift << 'EOF'
import Foundation

// Send notification to trigger connection
DistributedNotificationCenter.default().post(
    name: NSNotification.Name("TriggerFrameSenderConnection"),
    object: nil
)
print("Sent reconnection trigger")
EOF
swift /tmp/reconnect_sink.swift

echo ""
echo "6. Checking connection status..."
sleep 3

# Check logs
echo "Recent connection attempts:"
log stream --predicate 'process == "GigEVirtualCamera" AND (message CONTAINS "sink" OR message CONTAINS "queue")' --style compact 2>/dev/null &
PID=$!
sleep 5
kill $PID 2>/dev/null
wait $PID 2>/dev/null

echo ""
echo "Done. Check if video is now appearing in Photo Booth."