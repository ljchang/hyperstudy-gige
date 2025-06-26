//
//  AravisBridge.h
//  GigEVirtualCamera
//
//  Objective-C bridge to Aravis C library
//

#ifndef AravisBridge_h
#define AravisBridge_h

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

#ifdef __cplusplus
extern "C" {
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AravisCameraState) {
    AravisCameraStateDisconnected,
    AravisCameraStateConnecting,
    AravisCameraStateConnected,
    AravisCameraStateStreaming,
    AravisCameraStateError
};

@protocol AravisBridgeDelegate <NSObject>
- (void)aravisBridge:(id)bridge didReceiveFrame:(CVPixelBufferRef)pixelBuffer;
- (void)aravisBridge:(id)bridge didChangeState:(AravisCameraState)state;
- (void)aravisBridge:(id)bridge didEncounterError:(NSError *)error;
@end

@interface AravisCamera : NSObject
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *modelName;
@property (nonatomic, readonly) NSString *deviceId;
@property (nonatomic, readonly) NSString *ipAddress;
@end

@interface AravisBridge : NSObject

@property (nonatomic, weak) id<AravisBridgeDelegate> delegate;
@property (nonatomic, readonly) AravisCameraState state;
@property (nonatomic, readonly, nullable) AravisCamera *currentCamera;

// Discovery
+ (NSArray<AravisCamera *> *)discoverCameras;

// Connection
- (BOOL)connectToCamera:(AravisCamera *)camera;
- (BOOL)connectToCameraWithIP:(NSString *)ipAddress;
- (void)disconnect;

// Streaming
- (BOOL)startStreaming;
- (void)stopStreaming;

// Camera settings
- (BOOL)setFrameRate:(double)frameRate;
- (BOOL)setExposureTime:(double)exposureTimeUs;
- (BOOL)setGain:(double)gain;

// Get current settings
- (double)frameRate;
- (double)exposureTime;
- (double)gain;

@end

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif

#endif /* AravisBridge_h */