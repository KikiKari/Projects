#import <Foundation/Foundation.h>
#import <MobileVLCKit/MobileVLCKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^TLCNativeAudioReport)(BOOL active, double input, double output, double reduction, NSString * _Nullable error);
@interface TLCNativeVlcAudio : NSObject
@property(nonatomic, readonly) VLCMediaPlayer *player;
- (nullable instancetype)initWithReport:(TLCNativeAudioReport)report;
- (void)setProtectionEnabled:(BOOL)enabled strength:(NSInteger)strength NS_SWIFT_NAME(setProtection(enabled:strength:));
- (void)playURL:(NSURL *)url drawable:(UIView *)drawable NS_SWIFT_NAME(play(url:drawable:));
/* Completion runs after the native stopped event; MobileVLCKit's stop is async. */
- (void)stopWithCompletion:(void (^)(void))completion NS_SWIFT_NAME(stop(completion:));
@end
NS_ASSUME_NONNULL_END
