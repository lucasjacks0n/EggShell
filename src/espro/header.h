#import "rocketbootstrap.h"
@interface SBMediaController : NSObject {
	int _manualVolumeChangeCount;
	float _pendingVolumeChange;
	NSTimer* _volumeCommitTimer;
	BOOL _debounceVolumeRepeat;
	NSDictionary *_nowPlayingInfo;
}
+(id)sharedInstance;
-(void)cancelLockScreenIdleTimer;
-(void)turnOnScreenFullyWithBacklightSource:(int)arg1;
-(BOOL)play;
-(BOOL)togglePlayPause;
-(BOOL)isPlaying;
-(BOOL)changeTrack:(int)track;
@end

@interface SBUserAgent : NSObject
+(id)sharedUserAgent;
-(void)lockAndDimDevice;
-(void)handleMenuDoubleTap;
-(void)clickedMenuButton;
-(bool)handleHomeButtonSinglePressUp;
-(bool)handleHomeButtonDoublePressDown;
@end


@interface SBDeviceLockController : NSObject
+(id)sharedController;
-(void)_clearBlockedState;
-(BOOL)isPasscodeLocked;
@end

@interface CLLocationManager : NSObject
+ (void)setLocationServicesEnabled:(BOOL)arg1;
@end

@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
-(BOOL)attemptUnlockWithPasscode:(id)passcode;
@end

@interface SBHUDController : NSObject
+(id)sharedInstance;
-(void)hideHUD;
-(void)showHUD;
@end

@interface VolumeControl : NSObject
+(id)sharedVolumeControl;
-(void)toggleMute;
@end

@interface SBIconController : NSObject
-(id)lastTouchedIcon;
@end
