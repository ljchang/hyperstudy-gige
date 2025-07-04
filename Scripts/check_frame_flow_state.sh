#!/bin/bash

echo "=== Frame Flow State Check ==="
echo ""

# Get process PIDs
APP_PID=$(ps aux | grep "GigEVirtualCamera.app" | grep -v grep | awk '{print $2}')
EXT_PID=$(ps aux | grep "GigECameraExtension" | grep -v grep | awk '{print $2}')
PHOTO_PID=$(ps aux | grep -i "photo booth" | grep -v grep | awk '{print $2}')

echo "1. Process Status:"
if [ -n "$APP_PID" ]; then
    echo "   ✅ App running (PID: $APP_PID)"
else
    echo "   ❌ App NOT running"
fi

if [ -n "$EXT_PID" ]; then
    echo "   ✅ Extension running (PID: $EXT_PID)"
else
    echo "   ❌ Extension NOT running"
fi

if [ -n "$PHOTO_PID" ]; then
    echo "   ✅ Photo Booth running (PID: $PHOTO_PID)"
else
    echo "   ❌ Photo Booth NOT running"
fi

echo ""
echo "2. Recent Extension Activity (last 60 seconds):"
if [ -n "$EXT_PID" ]; then
    # Look for our debug markers in recent logs
    echo "   Checking for stream activity..."
    
    RECENT_LOGS=$(log show --process $EXT_PID --last 60s 2>/dev/null | tail -100)
    
    if echo "$RECENT_LOGS" | grep -q "SINK STREAM STARTING"; then
        echo "   ✅ Sink stream started"
    else
        echo "   ⚠️  No sink stream start detected"
    fi
    
    if echo "$RECENT_LOGS" | grep -q "SOURCE STREAM STARTING"; then
        echo "   ✅ Source stream started"
    else
        echo "   ⚠️  No source stream start detected"
    fi
    
    if echo "$RECENT_LOGS" | grep -q "consumeSampleBuffer callback triggered"; then
        echo "   ✅ Sink callback triggered"
    else
        echo "   ⚠️  No sink callback activity"
    fi
    
    if echo "$RECENT_LOGS" | grep -q "Sink received frame"; then
        echo "   ✅ Frames being received by sink"
    else
        echo "   ⚠️  No frames received by sink"
    fi
fi

echo ""
echo "3. App Frame Sending Status:"
if [ -n "$APP_PID" ]; then
    APP_LOGS=$(log show --process $APP_PID --last 60s 2>/dev/null | tail -100)
    
    if echo "$APP_LOGS" | grep -q "Sent frame.*to sink"; then
        echo "   ✅ App is sending frames to sink"
    else
        echo "   ⚠️  App is NOT sending frames"
    fi
fi

echo ""
echo "4. Summary:"
echo "   Based on the logs from the reinstall output:"
echo "   - Sink stream IS starting when Photo Booth connects"
echo "   - consumeSampleBuffer callback IS being triggered"
echo "   - But we need to check if frames are actually being processed"
echo ""
echo "   Next step: Check if the app is actually sending frames to the sink queue"