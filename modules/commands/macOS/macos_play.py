class payload:
    def __init__(self):
        self.name = "play"
        self.description = "tell iTunes to play"
        self.type = "applescript"
        self.id = 118

    def run(self,session,server,command):
        payload = "tell application \"iTunes\" to play"
        result = server.sendCommand(self.name,payload,self.type,session.conn)
        if result:
            print result
        return ""
