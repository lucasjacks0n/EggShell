class payload:
    def __init__(self):
        self.name = "getvol"
        self.description = "get output volume"
        self.type = "applescript"
	self.id = 112

    def run(self,session,server,command):
        payload = "output volume of (get volume settings)"
        result = server.sendCommand(self.name,payload,self.type,session.conn)
        if result:
            print result
        return ""
