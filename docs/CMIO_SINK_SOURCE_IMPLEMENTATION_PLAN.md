# CMIO Sink/Source Implementation Plan

## Overview

This document outlines the implementation plan to replace the current IOSurface sharing mechanism with the standard CMIO sink/source stream architecture for the GigE Virtual Camera. This approach will enable zero-copy frame transport from the GigE camera app to the CMIO extension using the framework's built-in transport mechanisms.

## Current Architecture Issues

1. **IOSurface Sharing via App Groups**: Complex and unreliable due to sandboxing
2. **Manual Synchronization**: Using UserDefaults for frame coordination is prone to race conditions
3. **Bypassing CMIO Transport**: Not using the framework's built-in zero-copy mechanisms
4. **Lifecycle Management**: IOSurfaces created at init rather than when needed

## Proposed Architecture

### Component Diagram

```
┌─────────────────┐     CMSampleBuffer      ┌──────────────────────┐
│   GigE Camera   │ ──────────────────────> │   CMIO Extension     │
│      App        │   via CMSimpleQueue     │                      │
│                 │                         │ ┌────────────────┐   │
│ ┌─────────────┐ │                         │ │  Sink Stream   │   │
│ │CMIOSink     │ │                         │ │                │   │
│ │Connector    │ │                         │ └───────┬────────┘   │
│ └─────────────┘ │                         │         │            │
└─────────────────┘                         │    DeviceSource     │
                                           │    (Bridge)         │
                                           │         │            │
                                           │ ┌───────▼────────┐   │
                                           │ │ Source Stream  │   │
                                           │ │                │   │
                                           │ └───────┬────────┘   │
                                           └─────────┼────────────┘
                                                     │
                                                     ▼
                                           ┌─────────────────┐
                                           │ Client Apps     │
                                           │ (QuickTime,     │
                                           │  Zoom, etc.)    │
                                           └─────────────────┘
```

### Key Components

1. **Sink Stream**: Receives frames from the app via CMIO's built-in transport
2. **Source Stream**: Sends frames to client applications
3. **DeviceSource Bridge**: Routes frames from sink to source with intelligent buffering
4. **CMIOSinkConnector**: App-side component that discovers and sends to sink stream

## Implementation Plan

### Phase 1: Extension Modifications

#### 1.1 Update GigEVirtualCameraExtensionProvider.swift

```swift
// Add sink stream to DeviceSource
class GigEVirtualCameraExtensionDeviceSource {
    private var sourceStreamSource: SourceStreamSource!
    private var sinkStreamSource: SinkStreamSource!
    private var streamingCounter = 0
    private var isSinking = false
    
    init() {
        // Create both streams
        createStreams()
        
        // Add streams to device
        try device.addStream(sourceStreamSource.stream)
        try device.addStream(sinkStreamSource.stream)
    }
    
    // Bridge implementation
    func startSinkStreaming() {
        isSinking = true
        
        sinkStreamSource.consumeSampleBuffer = { [weak self] buffer in
            guard let self = self else { return }
            
            // Forward to source if clients connected
            if self.streamingCounter > 0 {
                self.sourceStreamSource.stream.send(buffer, ...)
            }
        }
    }
}
```

#### 1.2 Implement SinkStreamSource

```swift
class SinkStreamSource: NSObject, CMIOExtensionStreamSource {
    var consumeSampleBuffer: ((CMSampleBuffer) -> Void)?
    
    func startStream() throws {
        // Notify device source
        deviceSource.startSinkStreaming()
        
        // Start consuming buffers
        try subscribe()
    }
    
    private func subscribe() throws {
        stream.consumeSampleBuffer(from: client) { [weak self] (buffer, ...) in
            defer {
                // Re-subscribe for next buffer
                if self?.stream.state == .running {
                    try? self?.subscribe()
                }
            }
            
            if let buffer = buffer {
                self?.consumeSampleBuffer?(buffer)
            }
        }
    }
}
```

### Phase 2: App Modifications

#### 2.1 Create CMIOSinkConnector

```swift
class CMIOSinkConnector {
    private var sinkQueue: CMSimpleQueue?
    private let virtualCameraName = "GigE Virtual Camera"
    
    func connect() -> Bool {
        // 1. Find device ID
        guard let deviceID = findDeviceID(name: virtualCameraName) else {
            return false
        }
        
        // 2. Find sink stream ID
        guard let sinkStreamID = findSinkStreamID(deviceID: deviceID) else {
            return false
        }
        
        // 3. Get buffer queue
        guard let queue = getBufferQueue(streamID: sinkStreamID) else {
            return false
        }
        
        sinkQueue = queue
        
        // 4. Start stream
        return startStream(deviceID: deviceID, streamID: sinkStreamID)
    }
    
    func sendFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let queue = sinkQueue else { return }
        
        // Create CMSampleBuffer
        let sampleBuffer = createSampleBuffer(from: pixelBuffer)
        
        // Enqueue
        CMSimpleQueueEnqueue(queue, element: sampleBuffer)
    }
}
```

#### 2.2 Update CameraManager

```swift
class CameraManager {
    private let sinkConnector = CMIOSinkConnector()
    
    func startStreaming() {
        // Connect to sink
        if sinkConnector.connect() {
            // Start GigE capture
            startGigECapture()
        }
    }
    
    func handleFrame(_ pixelBuffer: CVPixelBuffer) {
        // Send to sink instead of IOSurface
        sinkConnector.sendFrame(pixelBuffer)
    }
}
```

### Phase 3: Stream State Coordination

#### 3.1 App Groups Signaling

```swift
// Extension signals when it needs frames
class StreamStateCoordinator {
    private let groupDefaults = UserDefaults(suiteName: "group....")
    
    func signalNeedFrames() {
        groupDefaults?.set([
            "streamActive": true,
            "timestamp": Date().timeIntervalSince1970
        ], forKey: "StreamState")
    }
    
    func signalStreamStopped() {
        groupDefaults?.removeObject(forKey: "StreamState")
    }
}
```

### Phase 4: Cleanup

1. Remove `IOSurfaceFrameWriter.swift`
2. Remove `IOSurfaceFrameSharing.swift`
3. Remove `SharedMemoryFramePool` from extension
4. Clean up `FrameCoordinator` code

## Testing Plan

### 1. Unit Tests
- Test sink stream discovery
- Test buffer queue acquisition
- Test frame enqueueing

### 2. Integration Tests
- Verify frame flow from app to extension
- Test with multiple simultaneous clients
- Verify zero-copy performance

### 3. System Tests
- Test with QuickTime Player
- Test with Photo Booth
- Test with video conferencing apps

### 4. Monitoring Script

```bash
#!/bin/bash
# monitor_sink_source_flow.sh

echo "Monitoring CMIO sink/source flow..."

# Watch for sink connection
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND category == "SinkStream"' &

# Watch for frame routing
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera" AND message CONTAINS "frame"' &

# Monitor system CMIO events
log stream --predicate 'subsystem == "com.apple.cmio"'
```

## Benefits

1. **Simplicity**: Uses framework's intended architecture
2. **Performance**: True zero-copy via IOSurface transport
3. **Reliability**: Framework handles IPC complexity
4. **Compatibility**: Works with macOS security model
5. **Maintainability**: Less custom code to maintain

## Timeline

- **Day 1**: Implement sink stream in extension
- **Day 2**: Create CMIOSinkConnector in app
- **Day 3**: Add stream state coordination
- **Day 4**: Testing and debugging
- **Day 5**: Cleanup and optimization

## Success Criteria

1. Frames flow from GigE camera to virtual camera clients
2. Zero memory copies in transport path
3. Proper stream lifecycle management
4. No regression in functionality
5. Improved reliability over IOSurface sharing