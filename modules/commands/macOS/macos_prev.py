class payload:
    def __init__(self):
        self.name = "prev"
        self.description = "tell iTunes to play previous track"
        self.type = "applescript"
        self.id = 120
        
    def run(self,session,server,command):
        payload = "tell application \"iTunes\" to previous track"
        result = server.sendCommand(self.name,payload,self.type,session.conn)
        if result:
            print result
        return ""
