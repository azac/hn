#import "VoiceNewsAppDelegate.h"
#import "HTMLParser.h"

@implementation VoiceNewsAppDelegate

NSStatusItem *statusItem;
NSMenu *theMenu;
NSMenuItem *speakerItem;
NSMenuItem *notificationItem;

int previousId=0;


- (id) init {
    
    self = [super init];
    if (self) {
        
        _speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
                
    }
    
    return self;
    
}


-(IBAction)menuNotificationClick:(id)sender {

    if ([notificationItem state]) {
        
        if ([notificationItem state]==NSOnState) {
            
            [notificationItem setState:NSOffState];
            
        } else {
            
            [notificationItem setState:NSOnState];
            
        }
        
        
    } else {
        
        [notificationItem setState:NSOnState];
        
    }
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setInteger:[notificationItem state]+1 forKey:@"notification"];
    
}



-(IBAction)menuSpeakerClick:(id)sender {
    
    if ([speakerItem state]) {
        
        if ([speakerItem state]==NSOnState) {
            
            [speakerItem setState:NSOffState];
            
        } else {
            
            [speakerItem setState:NSOnState];
            
        }
        
                   
    } else {
        
        [speakerItem setState:NSOnState];
        
    }
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    [prefs setInteger:[speakerItem state] forKey:@"speaker"];

}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(speak:) userInfo:nil repeats:YES];

    
    theMenu = [[NSMenu alloc] initWithTitle:@""];
    [theMenu setAutoenablesItems:NO];


    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSInteger speakerValue = [prefs integerForKey:@"speaker"];
    NSInteger notificationValue = [prefs integerForKey:@"notification"];
    
    speakerItem = [[NSMenuItem alloc] initWithTitle:@"Speaker" action:@selector(menuSpeakerClick:) keyEquivalent:@""];
    [speakerItem setState:speakerValue];
    [theMenu addItem:speakerItem];
    

    notificationItem = [[NSMenuItem alloc] initWithTitle:@"Notification" action:@selector(menuNotificationClick:) keyEquivalent:@""];

    if (notificationValue==1 || notificationValue==2) {
        
        [notificationItem setState:notificationValue-1];
    
    } else {

        [notificationItem setState:NSOnState];
        [prefs setInteger:[notificationItem state]+1 forKey:@"notification"];
        
    }
    
    [theMenu addItem:notificationItem];
    
    [theMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *tItem = nil;
    tItem = [theMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    [tItem setKeyEquivalentModifierMask:NSCommandKeyMask];
    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
  
    [statusItem setTitle:@"hn"];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:theMenu];
    
    [self speak:self];

    
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}


- (void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    
    NSURL *url = [NSURL URLWithString:[notification informativeText]];
    if( ![[NSWorkspace sharedWorkspace] openURL:url] )
        NSLog(@"Failed to open url: %@",[url description]);
    
}

- (void) userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{

    [center removeDeliveredNotification: notification];
}


- (IBAction)speak:(id)sender {
    
    
    NSError *error = nil;
        
    NSURL *url = [NSURL URLWithString:@"https://news.ycombinator.com/newest"];
    NSData *responseData = [NSData dataWithContentsOfURL:url];
    
    NSString *analized = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    
    HTMLParser *parser = [[HTMLParser alloc] initWithString:analized error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return;
    }
    
    HTMLNode *bodyNode = [parser body];
    
    HTMLNode *mainTableNode = [[bodyNode findChildTags:@"table"] objectAtIndex:2];
    
    NSArray *trNodes = [mainTableNode findChildTags:@"tr"];
    
    int i = 0;
    
    for (HTMLNode *trNode in trNodes) {
        
        if (i % 3 ==0 && i<3) {
                    
            NSArray *aNodes = [trNode findChildTags:@"a"];
            
            HTMLNode *firstLink = [aNodes objectAtIndex:0];
            
            NSString *idString = [firstLink getAttributeNamed:@"id"];
            
            NSString *theId = [[idString componentsSeparatedByString:@"_"] objectAtIndex:1];
            
            HTMLNode *secondLink = [aNodes objectAtIndex:1];
            
            NSString *theTitle = [secondLink contents];
            
            NSString *theUrl = [secondLink getAttributeNamed:@"href"];
            
            if ([[theUrl substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"item"]) {
                                
                theUrl = [NSString stringWithFormat:@"http://news.ycombinator.com/%@", theUrl];
                
            }
            
            int postId = [theId intValue];
            
            if (previousId != postId) {
                              
                if ([speakerItem state]==NSOnState) {
                    
                    [_speechSynth startSpeakingString:theTitle];

                }
                

                if ([notificationItem state]==NSOnState) {
                
                    NSUserNotification *notification = [[NSUserNotification alloc] init];
                    [notification setTitle:@"hn"];
                    [notification setSubtitle:theTitle];
                    [notification setInformativeText:theUrl];
                
                    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
                    [center setDelegate:self];
                    [center deliverNotification:notification];
                }
                
            }
            
            previousId = postId;
                               
        }

        i++;        
        
    }
    
}


@end
