#import <AVFoundation/AVFoundation.h>

%hook AVAudioSession

- (BOOL)setCategory:(NSString *)category error:(NSError **)outError {
    // Check for explicit string identifiers
    if ([category isEqualToString:@"AVAudioSessionCategorySoloAmbient"] || 
        [category isEqualToString:@"AVAudioSessionCategoryPlayback"]) {
        return %orig(@"AVAudioSessionCategoryAmbient", outError);
    }
    return %orig(category, outError);
}

- (BOOL)setCategory:(NSString *)category withOptions:(NSUInteger)options error:(NSError **)outError {
    if ([category isEqualToString:@"AVAudioSessionCategorySoloAmbient"] || 
        [category isEqualToString:@"AVAudioSessionCategoryPlayback"]) {
        // Explicitly pass 1 to force audio mixing options ('MixWithOthers')
        return %orig(@"AVAudioSessionCategoryAmbient", options | 1, outError);
    }
    return %orig(category, options, outError);
}

%end
