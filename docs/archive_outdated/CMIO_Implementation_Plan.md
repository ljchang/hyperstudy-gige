# CMIO Sink/Source Implementation Plan

## Overview
Implement the CMIO extension using the sink/source stream pattern where:
- Main app captures frames from GigE camera via Aravis
- Main app sends frames to extension's sink stream via CoreMediaIO C API
- Extension provides frames from source stream to macOS applications
- Preview in main app shows exactly what's being sent to virtual camera

## Architecture

```
┌─────────────────────────────────────┐     ┌─────────────────────────────────────┐
│        Main App (Sandbox)           │     │    Extension (Strict Sandbox)       │
│                                     │     │                                     │
│  ┌─────────────────┐               │     │  ┌─────────────────┐               │
│  │ Aravis/GigE     │               │     │  │ Sink Stream     │               │
│  │ Camera Input    │               │     │  │ (receives frames)│               │
│  └────────┬────────┘               │     │  └────────┬────────┘               │
│           │                        │     │           │                        │
│  ┌────────▼────────┐               │     │  ┌────────▼────────┐               │
│  │ Frame Processing│               │     │  │ Frame Queue     │               │
│  │ & Conversion    │               │     │  │ (CMSimpleQueue) │               │
│  └────────┬────────┘               │     │  └────────┬────────┘               │
│           │                        │     │           │                        │
│      ┌────┴────┐                   │     │  ┌────────▼────────┐               │
│      │         │                   │     │  │ Source Stream   │               │
│      ▼         ▼                   │     │  │ (provides frames)│               │
│  ┌────────┐ ┌──────────────┐     │     │  └────────┬────────┘               │
│  │Preview │ │CoreMediaIO    │     │     │           │                        │
│  │View    │ │C API Client   ├─────┼─────┼───────────┘                        │
│  └────────┘ └──────────────┘     │     │                                     │
└─────────────────────────────────────┘     └─────────────────────────────────────┘
                                                       │
                                                       ▼
                                            ┌─────────────────────┐
                                            │ macOS Applications  │
                                            │ (QuickTime, Zoom,   │
                                            │  FaceTime, etc.)    │
                                            └─────────────────────┘
```

## Implementation Steps

### Phase 1: Clean Up Extension (Remove Aravis Dependencies)

1. **Update CameraStreamSource.swift**
   - Remove `import` of GigECameraManager
   - Remove direct camera access
   - Implement frame queue to receive from sink stream
   - Keep frame format conversion logic

2. **Update CameraProviderSource.swift**
   - Keep basic CMIO provider implementation
   - Remove any Aravis-related code

3. **Update CameraDeviceSource.swift**
   - Add sink stream configuration
   - Keep source stream configuration
   - Remove direct camera references

### Phase 2: Implement Sink/Source Streams in Extension

1. **Create Sink Stream**
   ```swift
   // In CameraDeviceSource.swift
   let sinkStream = CMIOExtensionStream(
       localizedName: "GigE Camera Input",
       streamID: UUID(),
       streamFormat: formatDescription,
       device: device,
       direction: .sink
   )
   ```

2. **Create Frame Queue**
   ```swift
   // Shared queue between sink and source
   private let frameQueue = CMSimpleQueueCreate(
       allocator: kCFAllocatorDefault,
       capacity: 30,
       callbacks: nil
   )
   ```

3. **Implement Sink Stream Handler**
   ```swift
   func stream(_ stream: CMIOExtensionStream, 
               didReceiveSampleBuffer sampleBuffer: CMSampleBuffer) {
       // Enqueue received frame
       CMSimpleQueueEnqueue(frameQueue, sampleBuffer)
   }
   ```

4. **Update Source Stream to Use Queue**
   ```swift
   func startStream() {
       streamingTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, 
                                           repeats: true) { _ in
           if let buffer = CMSimpleQueueDequeue(frameQueue) as? CMSampleBuffer {
               stream.send(sampleBuffer: buffer)
           }
       }
   }
   ```

### Phase 3: Implement CoreMediaIO C API Client in Main App

1. **Create CMIOClient.swift**
   ```swift
   class CMIOClient {
       private var deviceID: CMIODeviceID?
       private var sinkStreamID: CMIOStreamID?
       private var streamQueue: CMSimpleQueueRef?
       
       func findVirtualCamera() -> Bool
       func connectToSinkStream() -> Bool
       func sendFrame(_ pixelBuffer: CVPixelBuffer, timestamp: CMTime)
   }
   ```

2. **Discovery Implementation**
   - Use `kCMIOHardwarePropertyDevices` to enumerate devices
   - Match by device name or unique identifier
   - Find sink stream in device's streams array

3. **Frame Sending**
   - Convert CVPixelBuffer to CMSampleBuffer with timing
   - Use `CMSimpleQueueEnqueue` to send to sink stream

### Phase 4: Integrate with Existing Camera Pipeline

1. **Update CameraManager.swift**
   - Add CMIOClient instance
   - In frame callback from Aravis, send to both:
     - Preview view (existing)
     - CMIOClient (new)

2. **Frame Flow**
   ```swift
   // In AravisBridge frame callback
   func handleFrame(pixelBuffer: CVPixelBuffer) {
       // 1. Send to preview
       previewDelegate?.updateFrame(pixelBuffer)
       
       // 2. Send to virtual camera
       cmioClient?.sendFrame(pixelBuffer, timestamp: CMTime.now)
   }
   ```

### Phase 5: Update Build Configuration

1. **Extension Build Settings**
   - Remove Aravis library search paths
   - Remove Aravis header search paths
   - Remove Aravis linking flags
   - Keep only system frameworks

2. **Main App Build Settings**
   - Keep all Aravis dependencies
   - Add CoreMediaIO framework if not present

## Key Implementation Details

### Frame Format Handling
- Main app handles all format conversion
- Extension receives ready-to-use CMSampleBuffers
- No format conversion needed in extension

### Timing and Synchronization
- Use presentation timestamps from GigE camera
- Maintain consistent frame rate
- Handle dropped frames gracefully

### Error Handling
- Graceful fallback if extension not running
- Handle disconnection/reconnection
- Log errors appropriately

### Testing Strategy
1. Test extension with static test pattern first
2. Test sink stream reception with simple frames
3. Test full pipeline with GigE camera
4. Verify in multiple applications (QuickTime, Zoom, etc.)

## Benefits of This Approach

1. **Clean separation** - Camera access only in main app
2. **Reuses existing code** - Preview pipeline already works
3. **User-friendly** - Settings in UI automatically apply to virtual camera
4. **Maintainable** - Clear boundaries between components
5. **Secure** - Extension has minimal privileges
6. **Efficient** - Single frame processing pipeline

## Next Steps

1. Start with Phase 1 - Remove Aravis from extension
2. Implement basic sink/source with test pattern
3. Add CoreMediaIO client to main app
4. Connect to existing camera pipeline
5. Test and debug