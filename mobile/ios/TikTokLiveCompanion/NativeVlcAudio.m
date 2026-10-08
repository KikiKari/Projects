#import "NativeVlcAudio.h"
#import <AVFoundation/AVFoundation.h>
#include <stdatomic.h>
#include "../../shared/native/tlc_peak_limiter.h"

typedef void (*tlc_play_cb)(void *, const void *, unsigned, int64_t);
typedef void (*tlc_time_cb)(void *, int64_t);
extern void *libvlc_media_player_new(void *);
extern void libvlc_audio_set_callbacks(void *, tlc_play_cb, tlc_time_cb, tlc_time_cb, tlc_time_cb, void (*)(void *), void *);
extern void libvlc_audio_set_format(void *, const char *, unsigned, unsigned);
extern int64_t libvlc_clock(void);

@interface TLCNativeVlcAudio () {
    void *_nativePlayer;
    tlc_peak_limiter *_limiter;
    atomic_bool _enabled, _closing, _failed;
    atomic_int _strength;
    AVAudioEngine *_engine;
    AVAudioPlayerNode *_node;
    AVAudioFormat *_format;
    dispatch_semaphore_t _slots;
    BOOL _started, _hasPlayed;
    TLCNativeAudioReport _report;
    id _stopObserver;
    CFTimeInterval _lastReport;
}
- (void)consume:(const float *)pcm frames:(unsigned)frames pts:(int64_t)pts;
- (void)control:(int)operation;
@end

static void tlc_play(void *opaque, const void *pcm, unsigned frames, int64_t pts) {
    @autoreleasepool { [(__bridge TLCNativeVlcAudio *)opaque consume:pcm frames:frames pts:pts]; }
}
static void tlc_pause(void *opaque, int64_t pts) { (void)pts; [(__bridge TLCNativeVlcAudio *)opaque control:0]; }
static void tlc_resume(void *opaque, int64_t pts) { (void)pts; [(__bridge TLCNativeVlcAudio *)opaque control:1]; }
static void tlc_flush(void *opaque, int64_t pts) { (void)pts; [(__bridge TLCNativeVlcAudio *)opaque control:2]; }
static void tlc_drain(void *opaque) { [(__bridge TLCNativeVlcAudio *)opaque control:3]; }

@implementation TLCNativeVlcAudio
- (instancetype)initWithReport:(TLCNativeAudioReport)report {
    if (!(self = [super init])) return nil;
    _report = [report copy];
    atomic_init(&_enabled, false); atomic_init(&_closing, false);
    atomic_init(&_failed, false); atomic_init(&_strength, 30);
    _limiter = tlc_peak_create(48000, 2);
    if (!_limiter) return nil;
    _engine = [AVAudioEngine new]; _node = [AVAudioPlayerNode new];
    _format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:48000 channels:2 interleaved:NO];
    [_engine attachNode:_node]; [_engine connect:_node to:_engine.mainMixerNode format:_format];
    NSError *error = nil;
    if (![_engine startAndReturnError:&error]) return nil;
    _slots = dispatch_semaphore_create(4);
    VLCLibrary *library = [[VLCLibrary alloc] initWithOptions:@[@"--network-caching=1500"]];
    _nativePlayer = libvlc_media_player_new(library.instance);
    if (!_nativePlayer) return nil;
    // Pinned VLCKit initializer takes ownership, without retaining the pointer.
    _player = [[VLCMediaPlayer alloc] initWithLibVLCInstance:_nativePlayer andLibrary:library];
    libvlc_audio_set_format(_nativePlayer, "FL32", 48000, 2);
    libvlc_audio_set_callbacks(_nativePlayer, tlc_play, tlc_pause, tlc_resume, tlc_flush, tlc_drain, (__bridge void *)self);
    return self;
}
- (void)setProtectionEnabled:(BOOL)enabled strength:(NSInteger)strength {
    atomic_store(&_strength, (int)MAX(0, MIN(100, strength)));
    atomic_store(&_enabled, enabled);
}
- (void)playURL:(NSURL *)url drawable:(UIView *)drawable {
    _player.drawable = drawable;
    _player.media = [VLCMedia mediaWithURL:url];
    _hasPlayed = YES;
    [_player play];
}
- (void)fail:(NSString *)message {
    if (atomic_exchange(&_failed, true) || atomic_load(&_closing)) return;
    [_node stop];
    dispatch_async(dispatch_get_main_queue(), ^{ if (!atomic_load(&self->_closing)) self->_report(NO, -100, -100, 0, message); });
}
- (void)consume:(const float *)pcm frames:(unsigned)frames pts:(int64_t)pts {
    for (unsigned offset = 0; offset < frames; ) {
        if (atomic_load(&_closing) || atomic_load(&_failed)) return;
        dispatch_semaphore_t slots = _slots;
        while (dispatch_semaphore_wait(slots, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_MSEC))) {
            if (atomic_load(&_closing) || atomic_load(&_failed)) return;
        }
        unsigned count = MIN(512, frames - offset);
        float rendered[512 * 2];
        tlc_peak_report report = tlc_peak_process(_limiter, pcm ? pcm + offset * 2 : NULL,
            rendered, count, atomic_load(&_enabled), atomic_load(&_strength));
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_format frameCapacity:count];
        if (!buffer) { dispatch_semaphore_signal(slots); [self fail:@"Nativer Audiopuffer nicht verfügbar"]; return; }
        buffer.frameLength = count;
        for (unsigned i = 0; i < count; ++i) {
            buffer.floatChannelData[0][i] = rendered[i * 2];
            buffer.floatChannelData[1][i] = rendered[i * 2 + 1];
        }
        [_node scheduleBuffer:buffer completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType type) {
            (void)type; dispatch_semaphore_signal(slots);
        }];
        if (!_started) {
            int64_t until = pts + offset * 1000000LL / 48000 - libvlc_clock();
            if (until > 2000000) { [self fail:@"VLC-Audiozeit außerhalb des Ausgabefensters"]; return; }
            uint64_t hostTime = [AVAudioTime hostTimeForSeconds:NSProcessInfo.processInfo.systemUptime + MAX(0, until) / 1000000.0];
            [_node playAtTime:[AVAudioTime timeWithHostTime:hostTime]];
            _started = YES;
        }
        CFTimeInterval now = NSProcessInfo.processInfo.systemUptime;
        if (now - _lastReport >= 0.1) {
            _lastReport = now; BOOL enabled = atomic_load(&_enabled);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!atomic_load(&self->_closing) && !atomic_load(&self->_failed))
                    self->_report(enabled, report.input_dbfs, report.output_dbfs, report.reduction_db, nil);
            });
        }
        offset += count;
    }
}
- (void)control:(int)operation {
    if (atomic_load(&_closing) || atomic_load(&_failed)) return;
    switch (operation) {
        case 0: [_node pause]; break;
        case 1: if (_started) [_node play]; break;
        case 2:
            [_node stop]; _slots = dispatch_semaphore_create(4);
            _started = NO; tlc_peak_reset(_limiter); break;
        case 3: [self consume:NULL frames:_limiter->delay pts:libvlc_clock()]; break;
    }
}
- (void)finishStop:(void (^)(void))completion {
    libvlc_audio_set_callbacks(_nativePlayer, NULL, NULL, NULL, NULL, NULL, NULL);
    [_node stop]; [_engine stop]; _player.drawable = nil;
    if (_stopObserver) { [NSNotificationCenter.defaultCenter removeObserver:_stopObserver]; _stopObserver = nil; }
    completion();
}
- (void)stopWithCompletion:(void (^)(void))completion {
    if (atomic_exchange(&_closing, true)) return;
    [_node stop];
    if (!_hasPlayed) { [self finishStop:completion]; return; }
    // Observer deliberately retains this adapter until the asynchronous stop
    // event: the opaque callback pointer must remain alive until then.
    _stopObserver = [NSNotificationCenter.defaultCenter addObserverForName:VLCMediaPlayerStateChanged object:_player queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        (void)note;
        if (self.player.state == VLCMediaPlayerStateStopped) [self finishStop:completion];
    }];
    [_player stop];
}
- (void)dealloc {
    [_engine stop]; tlc_peak_destroy(_limiter);
}
@end
