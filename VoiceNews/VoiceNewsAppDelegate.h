
#import <Cocoa/Cocoa.h>

@interface VoiceNewsAppDelegate : NSObject <NSApplicationDelegate> {
    
        NSSpeechSynthesizer *_speechSynth;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)speak:(id)sender;
- (IBAction)menuSpeakerClick:(id)sender;
- (IBAction)menuNotificationClick:(id)sender;

@end
