class payload:
    def __init__(self):
        self.name = "pause"
        self.description = "tell iTunes to pause"
        self.type = "applescript"
        self.id = 119

    def run(self,session,server,command):
        payload = "tell application \"iTunes\" to pause"
        result = server.sendCommand(self.name,payload,self.type,session.conn)
        if result:
            print result
        return ""
