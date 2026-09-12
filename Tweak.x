#import <AVFoundation/AVFoundation.h>

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
        return %orig(@"AVAudioSessionCategoryAmbient", options | 1, outError); // 1 = AVAudioSessionCategoryOptionMixWithOthers
    }
    return %orig(category, options, outError);
}

%end
