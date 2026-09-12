#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

// Global variable to track whether TikTok videos should be muted
static BOOL isTikTokMuted = NO;

// 1. SYSTEM AUDIO HOOK: Stop TikTok from ever hijacking background music
%hook AVAudioSession
- (BOOL)setCategory:(NSString *)category error:(NSError **)outError {
    if ([category isEqualToString:@"AVAudioSessionCategorySoloAmbient"] || 
        [category isEqualToString:@"AVAudioSessionCategoryPlayback"]) {
        return %orig(@"AVAudioSessionCategoryAmbient", outError);
    }
    return %orig(category, outError);
}

- (BOOL)setCategory:(NSString *)category withOptions:(NSUInteger)options error:(NSError **)outError {
    if ([category isEqualToString:@"AVAudioSessionCategorySoloAmbient"] || 
        [category isEqualToString:@"AVAudioSessionCategoryPlayback"]) {
        return %orig(@"AVAudioSessionCategoryAmbient", options | 1, outError); // 1 = MixWithOthers
    }
    return %orig(category, options, outError);
}
%end

// 2. VIDEO PLAYER HOOK: Override video volume based on our button status
%hook NOVVideoPlayer 
- (void)setVolume:(float)volume {
    if (isTikTokMuted) {
        %orig(0.0f); // Force video silence
    } else {
        %orig(volume); // Let regular sound play if unmuted
    }
}
%end

// 3. UI BUTTON HOOK: Inject a floating mute overlay button into the main feed view
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;

    // Verify if we are looking at the main TikTok feed controller
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Aweme"] || [className containsString:@"Feed"]) {
        
        // Prevent duplicate buttons from drawing on screen
        if ([self.view viewWithTag:999]) return;

        // Draw a clean, small floating button in the upper corner
        UIButton *muteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        muteButton.frame = CGRectMake(20, 60, 45, 45); // Adjust dimensions safely below the status bar
        muteButton.layer.cornerRadius = 22.5;
        muteButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        muteButton.tag = 999;
        
        // Use standard system emojis as visual labels
        [muteButton setTitle:@"🔊" forState:UIControlStateNormal];
        [muteButton addTarget:self action:@selector(toggleTikTokMuteState:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:muteButton];
        [self.view bringSubviewToFront:muteButton];
    }
}

// Add the custom click action method to the controller runtime
%new
- (void)toggleTikTokMuteState:(UIButton *)sender {
    isTikTokMuted = !isTikTokMuted;
    
    if (isTikTokMuted) {
        [sender setTitle:@"🔇" forState:UIControlStateNormal];
        sender.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.6];
    } else {
        [sender setTitle:@"🔊" forState:UIControlStateNormal];
        sender.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    }
}
%end
