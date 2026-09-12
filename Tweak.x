#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static BOOL gMuted = YES;
static UIButton *gButton;

static BOOL IsTikTok(void) {
    NSString *bid = NSBundle.mainBundle.bundleIdentifier ?: @"";
    return [bid rangeOfString:@"musically" options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [bid rangeOfString:@"tiktok" options:NSCaseInsensitiveSearch].location != NSNotFound;
}

static void ApplyMuteToObject(id obj) {
    if (!obj || !gMuted) return;
    @try {
        if ([obj respondsToSelector:@selector(setMuted:)]) ((void (*)(id, SEL, BOOL))objc_msgSend)(obj, @selector(setMuted:), YES);
        if ([obj respondsToSelector:@selector(setVolume:)]) ((void (*)(id, SEL, float))objc_msgSend)(obj, @selector(setVolume:), 0.0f);
        if ([obj respondsToSelector:@selector(setOutputVolume:)]) ((void (*)(id, SEL, float))objc_msgSend)(obj, @selector(setOutputVolume:), 0.0f);
    } @catch (__unused NSException *e) {}
}

static void ToggleMute(void) {
    gMuted = !gMuted;
    [gButton setTitle:(gMuted ? @"UNMUTE" : @"MUTE") forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TikTokMuteAudioChanged" object:nil userInfo:@{@"muted": @(gMuted)}];
}

static void InstallButton(void) {
    if (!IsTikTok() || gButton) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gButton) return;
        UIWindow *window = nil;
        for (UIWindow *w in UIApplication.sharedApplication.windows) {
            if (!w.hidden && w.alpha > 0.01 && w.windowLevel == UIWindowLevelNormal) { window = w; break; }
        }
        if (!window) return;

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(window.bounds.size.width - 110.0, 95.0, 96.0, 42.0);
        button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        button.backgroundColor = [UIColor colorWithWhite:0 alpha:0.72];
        button.layer.cornerRadius = 10.0;
        [button setTitle:(gMuted ? @"UNMUTE" : @"MUTE") forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        [button addTarget:[NSBlockOperation blockOperationWithBlock:^{ ToggleMute(); }] action:@selector(main) forControlEvents:UIControlEventTouchUpInside];
        [window addSubview:button];
        gButton = button;
    });
}

%hook AVPlayer
- (void)play {
    %orig;
    if (gMuted) {
        self.muted = YES;
        self.volume = 0.0f;
    }
}
- (void)setMuted:(BOOL)muted {
    %orig(gMuted ? YES : muted);
}
- (void)setVolume:(float)volume {
    %orig(gMuted ? 0.0f : volume);
}
%end

%hook AVAudioPlayer
- (void)play {
    %orig;
    if (gMuted) self.volume = 0.0f;
}
- (void)setVolume:(float)volume {
    %orig(gMuted ? 0.0f : volume);
}
%end

%hook AVAudioPlayerNode
- (void)play {
    %orig;
    ApplyMuteToObject(self);
}
%end

%hook AVAudioMixerNode
- (void)setOutputVolume:(float)volume {
    %orig(gMuted ? 0.0f : volume);
}
%end

%ctor {
    if (!IsTikTok()) return;
    gMuted = YES;
    InstallButton();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ InstallButton(); });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ InstallButton(); });
}
