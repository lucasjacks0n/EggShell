import base64
class payload:
    def __init__(self):
        self.name = "alert"
        self.description = "make alert show up on device"
        self.type = "native"
        self.id = 119

    def run(self,session,server,command):
        title = base64.b64encode(raw_input("title: "))
        message = base64.b64encode(raw_input("message: "))
        server.sendCommand(self.name,title+" "+message,self.type,session.conn)
        print title+" "+message;
        return ""
