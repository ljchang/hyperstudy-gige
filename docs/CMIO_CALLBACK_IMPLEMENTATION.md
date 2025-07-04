# CMIO Callback-Based Sink Stream Detection Implementation

## Overview

This document describes the new callback-based implementation for detecting CMIO sink streams when they become available. This replaces the previous polling-based approach with an event-driven system using CMIO property listeners.

## Architecture

### Key Components

1. **CMIOPropertyListener** (`GigECameraApp/CMIOPropertyListener.swift`)
   - Registers for CMIO hardware property change notifications
   - Monitors device additions/removals
   - Detects stream additions/removals on target devices
   - Posts system-wide notifications for stream lifecycle events

2. **CMIOSinkConnector** (updated in `CMIOFrameSender.swift`)
   - Uses CMIOPropertyListener for automatic sink detection
   - Implements retry logic with exponential backoff
   - Provides callbacks for connection state changes
   - Handles error conditions gracefully

3. **CameraManager** (updated)
   - Sets up callbacks for automatic Aravis streaming
   - Responds to sink stream availability
   - Removes manual connection logic

## How It Works

### 1. Initialization Flow

```
App Launch
    ↓
CameraManager creates CMIOSinkConnector
    ↓
CMIOSinkConnector creates CMIOPropertyListener
    ↓
Property listener registers for:
    - Hardware device list changes
    - Stream list changes on target device
    ↓
Existing devices/streams are checked
```

### 2. Sink Stream Discovery Flow

```
Extension creates sink stream
    ↓
CMIO posts kCMIODevicePropertyStreams change
    ↓
Property listener callback fires
    ↓
Listener detects new sink stream
    ↓
onSinkStreamDiscovered callback invoked
    ↓
CMIOSinkConnector automatically connects
    ↓
Connection success triggers Aravis streaming
```

### 3. Frame Flow with Callbacks

```
GigE Camera → Aravis Bridge
    ↓
Frame handler in CameraManager
    ↓
If sink connected: Send to CMIOSinkConnector
    ↓
CMIOSinkConnector enqueues to sink
    ↓
Extension receives and forwards to clients
```

## Key Features

### 1. Automatic Detection
- No polling required
- Immediate reaction to stream availability
- Lower CPU usage

### 2. Retry Logic
- Maximum 3 retry attempts
- 2-second delay between retries
- Automatic reset on success

### 3. Error Handling
- Specific error code handling for queue operations
- Connection state callbacks
- Graceful degradation on failures

### 4. Notifications
The following notifications are posted:
- `.cmioSinkStreamDiscovered` - When a sink stream is found
- `.cmioSinkStreamRemoved` - When a sink stream is removed
- `.cmioDeviceDiscovered` - When the virtual camera device appears
- `.cmioDeviceRemoved` - When the virtual camera device is removed

## Testing the Implementation

### 1. Build and Install
```bash
cd /Users/lukechang/Github/hyperstudy-gige
./Scripts/build_debug.sh
./Scripts/install_app.sh
```

### 2. Monitor Logs
```bash
# In one terminal, monitor app logs
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category CONTAINS "CMIOPropertyListener"'

# In another terminal, monitor sink connector logs
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "CMIOSinkConnector"'

# In a third terminal, monitor general flow
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND message CONTAINS "sink"'
```

### 3. Test Scenarios

#### Scenario 1: Normal Operation
1. Launch the app
2. Connect to a GigE camera (or use Test Camera)
3. Open Photo Booth or QuickTime
4. Select "GigE Virtual Camera"
5. Verify logs show:
   - "Sink stream discovered via callback"
   - "Successfully connected to virtual camera sink stream via property listener!"
   - "Starting Aravis streaming after sink connection"

#### Scenario 2: Extension Not Running
1. Stop the extension: `killall GigEVirtualCameraExtension`
2. Launch the app
3. Verify logs show waiting for sink stream
4. Open Photo Booth
5. Verify automatic connection when extension starts

#### Scenario 3: Retry Logic
1. Temporarily block the extension
2. Watch for retry attempts in logs
3. Verify maximum 3 retries with 2-second delays

### 4. Verification Script
```bash
#!/bin/bash
# test_callback_flow.sh

echo "Testing CMIO callback-based sink detection..."

# Check if property listener is active
if log show --last 1m --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' | grep -q "CMIO property listener started successfully"; then
    echo "✅ Property listener is active"
else
    echo "❌ Property listener not started"
fi

# Check for sink discovery
if log show --last 1m --predicate 'subsystem == "com.lukechang.GigEVirtualCamera"' | grep -q "Sink stream discovered via callback"; then
    echo "✅ Sink stream discovered via callback"
else
    echo "⏳ Waiting for sink stream discovery..."
fi

# Monitor for automatic connection
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND (message CONTAINS "discovered via callback" OR message CONTAINS "connected to virtual camera sink stream via property listener")'
```

## Benefits Over Previous Approach

1. **No Polling**: Event-driven instead of periodic checking
2. **Faster Response**: Immediate detection of stream availability
3. **Better Resource Usage**: No wasted CPU cycles checking
4. **More Robust**: Handles extension restarts gracefully
5. **Cleaner Code**: Separation of concerns between detection and connection

## Troubleshooting

### Sink Stream Not Detected
1. Check extension is running: `pgrep -f GigEVirtualCameraExtension`
2. Verify device UID matches: Check logs for "Found device: <UID>"
3. Ensure property listener started: Look for "CMIO property listener started successfully"

### Connection Failures
1. Check retry attempts in logs
2. Verify no other app is using the sink
3. Restart the extension if needed

### No Frames Flowing
1. Verify Aravis is streaming: Check GigECameraManager logs
2. Ensure sink is connected: Look for "Sink connector connected"
3. Check frame handler is registered

## Implementation Details

### Property Listener Callbacks
```swift
// C callback functions are bridged to Swift methods:
deviceListChangedCallback → handleDeviceListChanged()
streamListChangedCallback → handleStreamListChanged()
```

### Thread Safety
- All callbacks execute on main queue
- Property changes are handled asynchronously
- Frame sending is thread-safe

### Memory Management
- Proper cleanup in deinit
- Weak self references in closures
- Timer invalidation on cleanup