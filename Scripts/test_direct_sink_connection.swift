#!/usr/bin/swift

import Foundation
import CoreMediaIO

print("=== Testing Direct Sink Connection ===")

// Find the virtual camera device
var prop = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
)

var dataSize: UInt32 = 0
CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, &dataSize)

let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
var deviceIDs = Array(repeating: CMIODeviceID(0), count: deviceCount)

CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, dataSize, &dataSize, &deviceIDs)

for deviceID in deviceIDs {
    // Get device UID
    var uidProp = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )
    
    var uidSize: UInt32 = 0
    if CMIOObjectGetPropertyDataSize(deviceID, &uidProp, 0, nil, &uidSize) == kCMIOHardwareNoError {
        let uidPtr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
        defer { uidPtr.deallocate() }
        
        if CMIOObjectGetPropertyData(deviceID, &uidProp, 0, nil, uidSize, &uidSize, uidPtr) == kCMIOHardwareNoError,
           let uid = uidPtr.pointee as String?,
           uid == "4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4" {
            
            print("Found virtual camera device: \(deviceID)")
            
            // Get streams
            var streamsProp = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyStreams),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
            )
            
            var streamsSize: UInt32 = 0
            if CMIOObjectGetPropertyDataSize(deviceID, &streamsProp, 0, nil, &streamsSize) == kCMIOHardwareNoError {
                let streamCount = Int(streamsSize) / MemoryLayout<CMIOStreamID>.size
                var streamIDs = Array(repeating: CMIOStreamID(0), count: streamCount)
                
                if CMIOObjectGetPropertyData(deviceID, &streamsProp, 0, nil, streamsSize, &streamsSize, &streamIDs) == kCMIOHardwareNoError {
                    print("Found \(streamCount) streams: \(streamIDs)")
                    
                    for streamID in streamIDs {
                        // Get stream direction
                        var dirProp = CMIOObjectPropertyAddress(
                            mSelector: CMIOObjectPropertySelector(kCMIOStreamPropertyDirection),
                            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
                        )
                        
                        var direction: UInt32 = 0
                        let dirSize = UInt32(MemoryLayout<UInt32>.size)
                        
                        if CMIOObjectGetPropertyData(streamID, &dirProp, 0, nil, dirSize, &dataSize, &direction) == kCMIOHardwareNoError {
                            print("Stream \(streamID): direction = \(direction) (\(direction == 0 ? "sink" : "source"))")
                            
                            if direction == 0 { // Sink stream
                                print("\nAttempting to connect to sink stream \(streamID)...")
                                
                                // Try to get buffer queue
                                var queueUnmanaged: Unmanaged<CMSimpleQueue>?
                                let result = CMIOStreamCopyBufferQueue(
                                    streamID,
                                    { (streamID, token, refCon) in
                                        print("Queue alteration callback called")
                                    },
                                    nil,
                                    &queueUnmanaged
                                )
                                
                                if result == kCMIOHardwareNoError, let queue = queueUnmanaged?.takeRetainedValue() {
                                    print("✅ Successfully got buffer queue!")
                                    
                                    // Try to start the stream
                                    let startResult = CMIODeviceStartStream(deviceID, streamID)
                                    if startResult == kCMIOHardwareNoError {
                                        print("✅ Successfully started sink stream!")
                                        
                                        // Test sending a frame
                                        print("\nTesting frame send...")
                                        
                                        // Create a test pixel buffer
                                        let attrs: [CFString: Any] = [
                                            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                                            kCVPixelBufferWidthKey: 640,
                                            kCVPixelBufferHeightKey: 480,
                                            kCVPixelBufferIOSurfacePropertiesKey: [:]
                                        ]
                                        
                                        var pixelBuffer: CVPixelBuffer?
                                        CVPixelBufferCreate(kCFAllocatorDefault, 640, 480, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
                                        
                                        if let buffer = pixelBuffer {
                                            // Create sample buffer
                                            var formatDesc: CMVideoFormatDescription?
                                            CMVideoFormatDescriptionCreateForImageBuffer(
                                                allocator: kCFAllocatorDefault,
                                                imageBuffer: buffer,
                                                formatDescriptionOut: &formatDesc
                                            )
                                            
                                            var timingInfo = CMSampleTimingInfo(
                                                duration: CMTime.invalid,
                                                presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                                                decodeTimeStamp: CMTime.invalid
                                            )
                                            
                                            var sampleBuffer: CMSampleBuffer?
                                            CMSampleBufferCreateReadyWithImageBuffer(
                                                allocator: kCFAllocatorDefault,
                                                imageBuffer: buffer,
                                                formatDescription: formatDesc!,
                                                sampleTiming: &timingInfo,
                                                sampleBufferOut: &sampleBuffer
                                            )
                                            
                                            if let sample = sampleBuffer {
                                                let enqueueResult = CMSimpleQueueEnqueue(queue, element: Unmanaged.passRetained(sample).toOpaque())
                                                if enqueueResult == noErr {
                                                    print("✅ Successfully sent test frame to sink!")
                                                } else {
                                                    print("❌ Failed to enqueue frame: \(enqueueResult)")
                                                }
                                            }
                                        }
                                        
                                        // Stop the stream
                                        CMIODeviceStopStream(deviceID, streamID)
                                    } else {
                                        print("❌ Failed to start sink stream: \(startResult)")
                                    }
                                } else {
                                    print("❌ Failed to get buffer queue: \(result)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

print("\nTest complete.")