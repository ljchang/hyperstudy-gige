//
//  AravisBridge.mm
//  GigEVirtualCamera
//
//  Objective-C++ implementation bridging Aravis to Swift
//

#import "AravisBridge.h"
#import <dispatch/dispatch.h>

extern "C" {
#include <arv.h>
}

@implementation AravisCamera {
    NSString *_name;
    NSString *_modelName;
    NSString *_deviceId;
    NSString *_ipAddress;
}

- (instancetype)initWithDeviceId:(NSString *)deviceId 
                            name:(NSString *)name 
                       modelName:(NSString *)modelName 
                       ipAddress:(NSString *)ipAddress {
    self = [super init];
    if (self) {
        _deviceId = deviceId;
        _name = name;
        _modelName = modelName;
        _ipAddress = ipAddress;
    }
    return self;
}

@end

@interface AravisBridge () {
    ArvCamera *_camera;
    ArvStream *_stream;
    dispatch_queue_t _frameQueue;
    dispatch_source_t _frameTimer;
}
@end

@implementation AravisBridge

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = AravisCameraStateDisconnected;
        _frameQueue = dispatch_queue_create("com.lukechang.gigecamera.framequeue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    [self disconnect];
}

#pragma mark - Discovery

+ (NSArray<AravisCamera *> *)discoverCameras {
    arv_update_device_list();
    
    NSMutableArray<AravisCamera *> *cameras = [NSMutableArray array];
    guint n_devices = arv_get_n_devices();
    
    for (guint i = 0; i < n_devices; i++) {
        const char *device_id = arv_get_device_id(i);
        const char *physical_id = arv_get_device_physical_id(i);
        const char *model = arv_get_device_model(i);
        const char *vendor = arv_get_device_vendor(i);
        
        if (device_id) {
            NSString *name = [NSString stringWithFormat:@"%s %s", 
                            vendor ?: "Unknown", 
                            model ?: "Camera"];
            NSString *modelName = [NSString stringWithUTF8String:model ?: "Unknown"];
            NSString *deviceId = [NSString stringWithUTF8String:device_id];
            NSString *ipAddress = [NSString stringWithUTF8String:physical_id ?: ""];
            
            AravisCamera *camera = [[AravisCamera alloc] initWithDeviceId:deviceId
                                                                     name:name
                                                                modelName:modelName
                                                                ipAddress:ipAddress];
            [cameras addObject:camera];
        }
    }
    
    return cameras;
}

#pragma mark - Connection

- (BOOL)connectToCamera:(AravisCamera *)camera {
    return [self connectToCameraAtAddress:camera.ipAddress];
}

- (BOOL)connectToCameraAtAddress:(NSString *)ipAddress {
    @synchronized(self) {
        if (_state != AravisCameraStateDisconnected) {
            [self disconnect];
        }
        
        [self setState:AravisCameraStateConnecting];
        
        GError *error = NULL;
        _camera = arv_camera_new([ipAddress UTF8String], &error);
        
        if (!_camera) {
            [self handleError:error message:@"Failed to connect to camera"];
            if (error) g_error_free(error);
            return NO;
        }
        
        // Get camera info
        const char *vendor = arv_camera_get_vendor_name(_camera, NULL);
        const char *model = arv_camera_get_model_name(_camera, NULL);
        const char *device_id = arv_camera_get_device_id(_camera, NULL);
        
        _currentCamera = [[AravisCamera alloc] initWithDeviceId:[NSString stringWithUTF8String:device_id ?: ""]
                                                           name:[NSString stringWithFormat:@"%s %s", vendor ?: "", model ?: ""]
                                                      modelName:[NSString stringWithUTF8String:model ?: ""]
                                                      ipAddress:ipAddress];
        
        [self setState:AravisCameraStateConnected];
        return YES;
    }
}

- (void)disconnect {
    @synchronized(self) {
        [self stopStreaming];
        
        if (_camera) {
            g_object_unref(_camera);
            _camera = NULL;
        }
        
        _currentCamera = nil;
        [self setState:AravisCameraStateDisconnected];
    }
}

#pragma mark - Streaming

- (BOOL)startStreaming {
    if (!_camera || _state != AravisCameraStateConnected) {
        return NO;
    }
    
    GError *error = NULL;
    
    // Create stream
    _stream = arv_camera_create_stream(_camera, NULL, NULL, &error);
    if (!_stream) {
        [self handleError:error message:@"Failed to create stream"];
        if (error) g_error_free(error);
        return NO;
    }
    
    // Configure stream
    arv_camera_set_acquisition_mode(_camera, ARV_ACQUISITION_MODE_CONTINUOUS, NULL);
    
    // Get payload size
    guint payload = arv_camera_get_payload(_camera, NULL);
    
    // Push buffers
    for (int i = 0; i < 10; i++) {
        arv_stream_push_buffer(_stream, arv_buffer_new(payload, NULL));
    }
    
    // Start acquisition
    arv_camera_start_acquisition(_camera, NULL);
    
    [self setState:AravisCameraStateStreaming];
    
    // Start frame processing
    dispatch_async(_frameQueue, ^{
        [self processFrames];
    });
    
    return YES;
}

- (void)stopStreaming {
    if (_state == AravisCameraStateStreaming && _camera) {
        arv_camera_stop_acquisition(_camera, NULL);
    }
    
    if (_stream) {
        g_object_unref(_stream);
        _stream = NULL;
    }
    
    if (_state == AravisCameraStateStreaming) {
        [self setState:AravisCameraStateConnected];
    }
}

#pragma mark - Frame Processing

- (void)processFrames {
    while (_state == AravisCameraStateStreaming && _stream) {
        ArvBuffer *buffer = arv_stream_timeout_pop_buffer(_stream, 1000000); // 1 second timeout
        
        if (buffer) {
            if (arv_buffer_get_status(buffer) == ARV_BUFFER_STATUS_SUCCESS) {
                [self processBuffer:buffer];
            }
            arv_stream_push_buffer(_stream, buffer);
        }
    }
}

- (void)processBuffer:(ArvBuffer *)buffer {
    gint width, height;
    const void *data = arv_buffer_get_data(buffer, NULL);
    arv_buffer_get_image_region(buffer, NULL, NULL, &width, &height);
    ArvPixelFormat pixel_format = arv_buffer_get_image_pixel_format(buffer);
    
    // Convert to CVPixelBuffer based on format
    CVPixelBufferRef pixelBuffer = NULL;
    
    switch (pixel_format) {
        case ARV_PIXEL_FORMAT_MONO_8:
            [self createPixelBufferFromMono8:data width:width height:height pixelBuffer:&pixelBuffer];
            break;
            
        case ARV_PIXEL_FORMAT_BAYER_GR_8:
        case ARV_PIXEL_FORMAT_BAYER_RG_8:
        case ARV_PIXEL_FORMAT_BAYER_GB_8:
        case ARV_PIXEL_FORMAT_BAYER_BG_8:
            [self createPixelBufferFromBayer:data width:width height:height pixelFormat:pixel_format pixelBuffer:&pixelBuffer];
            break;
            
        case ARV_PIXEL_FORMAT_RGB_8_PACKED:
            [self createPixelBufferFromRGB:data width:width height:height pixelBuffer:&pixelBuffer];
            break;
            
        case ARV_PIXEL_FORMAT_BGR_8_PACKED:
            [self createPixelBufferFromBGR:data width:width height:height pixelBuffer:&pixelBuffer];
            break;
            
        default:
            NSLog(@"Unsupported pixel format: 0x%x (%s)", pixel_format, arv_pixel_format_to_gst_caps_string(pixel_format));
            return;
    }
    
    if (pixelBuffer && self.delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate aravisBridge:self didReceiveFrame:pixelBuffer];
            CVPixelBufferRelease(pixelBuffer);
        });
    }
}

- (void)createPixelBufferFromMono8:(const void *)data 
                            width:(size_t)width 
                           height:(size_t)height 
                      pixelBuffer:(CVPixelBufferRef *)pixelBuffer {
    // Convert Mono8 to BGRA for display
    CVPixelBufferCreate(kCFAllocatorDefault,
                       width,
                       height,
                       kCVPixelFormatType_32BGRA,
                       NULL,
                       pixelBuffer);
    
    CVPixelBufferLockBaseAddress(*pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(*pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(*pixelBuffer);
    
    const uint8_t *srcData = (const uint8_t *)data;
    uint8_t *dstData = (uint8_t *)baseAddress;
    
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            uint8_t gray = srcData[y * width + x];
            size_t dstIdx = y * bytesPerRow + x * 4;
            dstData[dstIdx + 0] = gray; // B
            dstData[dstIdx + 1] = gray; // G
            dstData[dstIdx + 2] = gray; // R
            dstData[dstIdx + 3] = 255;  // A
        }
    }
    
    CVPixelBufferUnlockBaseAddress(*pixelBuffer, 0);
}

- (void)createPixelBufferFromBayer:(const void *)data 
                             width:(size_t)width 
                            height:(size_t)height
                       pixelFormat:(ArvPixelFormat)bayerFormat
                       pixelBuffer:(CVPixelBufferRef *)pixelBuffer {
    // Create BGRA buffer
    CVPixelBufferCreate(kCFAllocatorDefault,
                       width,
                       height,
                       kCVPixelFormatType_32BGRA,
                       NULL,
                       pixelBuffer);
    
    CVPixelBufferLockBaseAddress(*pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(*pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(*pixelBuffer);
    
    const uint8_t *srcData = (const uint8_t *)data;
    uint8_t *dstData = (uint8_t *)baseAddress;
    
    // Simple bilinear interpolation for Bayer pattern
    // This is a basic implementation - for production use consider using
    // more sophisticated algorithms or hardware debayering if available
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            size_t srcIdx = y * width + x;
            size_t dstIdx = y * bytesPerRow + x * 4;
            
            uint8_t r = 0, g = 0, b = 0;
            
            // Determine the color of the current pixel based on Bayer pattern
            // and interpolate missing colors from neighbors
            BOOL isEvenRow = (y % 2 == 0);
            BOOL isEvenCol = (x % 2 == 0);
            
            if (bayerFormat == ARV_PIXEL_FORMAT_BAYER_RG_8) {
                if (isEvenRow && isEvenCol) {
                    // Red pixel
                    r = srcData[srcIdx];
                    g = [self averageNeighbors:srcData x:x y:y width:width height:height horizontal:YES vertical:YES];
                    b = [self averageNeighbors:srcData x:x y:y width:width height:height horizontal:NO vertical:NO];
                } else if (isEvenRow && !isEvenCol) {
                    // Green pixel (red row)
                    r = [self averageNeighbors:srcData x:x y:y width:width height:height horizontal:YES vertical:NO];
                    g = srcData[srcIdx];
                    b = [self averageNeighbors:srcData x:x y:y width:width height:height horizontal:NO vertical:YES];
                } else if (!isEvenRow && isEvenCol) {
                    // Green pixel (blue row)
                    r = [self averageNeighbors:srcData x:x y:y width:width height:height horizontal:NO vertical:YES];
                    g = srcData[srcIdx];
                    b = [self averageNeighbors:srcData x:x y:y width:width height:height horizontal:YES vertical:NO];
                } else {
                    // Blue pixel
                    r = [self averageNeighbors:srcData x:x y:y width:width height:height horizontal:NO vertical:NO];
                    g = [self averageNeighbors:srcData x:x y:y width:width height:height horizontal:YES vertical:YES];
                    b = srcData[srcIdx];
                }
            }
            // Add other Bayer patterns as needed (GR, GB, BG)
            else {
                // Fallback to grayscale for unsupported patterns
                r = g = b = srcData[srcIdx];
            }
            
            dstData[dstIdx + 0] = b;     // B
            dstData[dstIdx + 1] = g;     // G
            dstData[dstIdx + 2] = r;     // R
            dstData[dstIdx + 3] = 255;   // A
        }
    }
    
    CVPixelBufferUnlockBaseAddress(*pixelBuffer, 0);
}

- (uint8_t)averageNeighbors:(const uint8_t *)data 
                          x:(size_t)x 
                          y:(size_t)y 
                      width:(size_t)width 
                     height:(size_t)height
                 horizontal:(BOOL)horizontal
                   vertical:(BOOL)vertical {
    int sum = 0;
    int count = 0;
    
    if (horizontal) {
        if (x > 0) {
            sum += data[y * width + (x - 1)];
            count++;
        }
        if (x < width - 1) {
            sum += data[y * width + (x + 1)];
            count++;
        }
    }
    
    if (vertical) {
        if (y > 0) {
            sum += data[(y - 1) * width + x];
            count++;
        }
        if (y < height - 1) {
            sum += data[(y + 1) * width + x];
            count++;
        }
    }
    
    if (!horizontal && !vertical) {
        // Diagonal neighbors
        if (x > 0 && y > 0) {
            sum += data[(y - 1) * width + (x - 1)];
            count++;
        }
        if (x < width - 1 && y > 0) {
            sum += data[(y - 1) * width + (x + 1)];
            count++;
        }
        if (x > 0 && y < height - 1) {
            sum += data[(y + 1) * width + (x - 1)];
            count++;
        }
        if (x < width - 1 && y < height - 1) {
            sum += data[(y + 1) * width + (x + 1)];
            count++;
        }
    }
    
    return count > 0 ? (uint8_t)(sum / count) : 0;
}

- (void)createPixelBufferFromRGB:(const void *)data 
                           width:(size_t)width 
                          height:(size_t)height 
                     pixelBuffer:(CVPixelBufferRef *)pixelBuffer {
    // Convert RGB to BGRA
    CVPixelBufferCreate(kCFAllocatorDefault,
                       width,
                       height,
                       kCVPixelFormatType_32BGRA,
                       NULL,
                       pixelBuffer);
    
    CVPixelBufferLockBaseAddress(*pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(*pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(*pixelBuffer);
    
    const uint8_t *srcData = (const uint8_t *)data;
    uint8_t *dstData = (uint8_t *)baseAddress;
    
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            size_t srcIdx = y * width * 3 + x * 3;
            size_t dstIdx = y * bytesPerRow + x * 4;
            
            dstData[dstIdx + 0] = srcData[srcIdx + 2]; // B
            dstData[dstIdx + 1] = srcData[srcIdx + 1]; // G
            dstData[dstIdx + 2] = srcData[srcIdx + 0]; // R
            dstData[dstIdx + 3] = 255;                 // A
        }
    }
    
    CVPixelBufferUnlockBaseAddress(*pixelBuffer, 0);
}

- (void)createPixelBufferFromBGR:(const void *)data 
                           width:(size_t)width 
                          height:(size_t)height 
                     pixelBuffer:(CVPixelBufferRef *)pixelBuffer {
    // Convert BGR to BGRA
    CVPixelBufferCreate(kCFAllocatorDefault,
                       width,
                       height,
                       kCVPixelFormatType_32BGRA,
                       NULL,
                       pixelBuffer);
    
    CVPixelBufferLockBaseAddress(*pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(*pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(*pixelBuffer);
    
    const uint8_t *srcData = (const uint8_t *)data;
    uint8_t *dstData = (uint8_t *)baseAddress;
    
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            size_t srcIdx = y * width * 3 + x * 3;
            size_t dstIdx = y * bytesPerRow + x * 4;
            
            dstData[dstIdx + 0] = srcData[srcIdx + 0]; // B
            dstData[dstIdx + 1] = srcData[srcIdx + 1]; // G
            dstData[dstIdx + 2] = srcData[srcIdx + 2]; // R
            dstData[dstIdx + 3] = 255;                 // A
        }
    }
    
    CVPixelBufferUnlockBaseAddress(*pixelBuffer, 0);
}

#pragma mark - Camera Settings

- (BOOL)setFrameRate:(double)frameRate {
    if (!_camera) return NO;
    
    GError *error = NULL;
    arv_camera_set_frame_rate(_camera, frameRate, &error);
    
    if (error) {
        g_error_free(error);
        return NO;
    }
    return YES;
}

- (BOOL)setExposureTime:(double)exposureTimeUs {
    if (!_camera) return NO;
    
    GError *error = NULL;
    arv_camera_set_exposure_time(_camera, exposureTimeUs, &error);
    
    if (error) {
        g_error_free(error);
        return NO;
    }
    return YES;
}

- (BOOL)setGain:(double)gain {
    if (!_camera) return NO;
    
    GError *error = NULL;
    arv_camera_set_gain(_camera, gain, &error);
    
    if (error) {
        g_error_free(error);
        return NO;
    }
    return YES;
}

- (double)frameRate {
    if (!_camera) return 0;
    return arv_camera_get_frame_rate(_camera, NULL);
}

- (double)exposureTime {
    if (!_camera) return 0;
    return arv_camera_get_exposure_time(_camera, NULL);
}

- (double)gain {
    if (!_camera) return 0;
    return arv_camera_get_gain(_camera, NULL);
}

#pragma mark - Private

- (void)setState:(AravisCameraState)state {
    _state = state;
    if (self.delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate aravisBridge:self didChangeState:state];
        });
    }
}

- (void)handleError:(GError *)error message:(NSString *)message {
    NSString *errorMessage = error ? [NSString stringWithUTF8String:error->message] : @"Unknown error";
    NSError *nsError = [NSError errorWithDomain:@"AravisBridge" 
                                           code:error ? error->code : -1
                                       userInfo:@{NSLocalizedDescriptionKey: message,
                                                NSLocalizedFailureReasonErrorKey: errorMessage}];
    
    [self setState:AravisCameraStateError];
    
    if (self.delegate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate aravisBridge:self didEncounterError:nsError];
        });
    }
}

@end