class payload:
    def __init__(self):
        self.name = "next"
        self.description = "tell iTunes to play next track"
        self.type = "applescript"
        self.id = 121

    def run(self,session,server,command):
        payload = "tell application \"iTunes\" to next track"
        server.sendCommand(self.name,payload,self.type,session.conn)
        return ""
