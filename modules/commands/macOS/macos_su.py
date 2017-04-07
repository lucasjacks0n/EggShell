import time
class payload:
    def __init__(self):
        self.name = "su"
        self.description = "su login"
        self.type = "eggsu"
        self.id = 127

    def run(self,session,server,command):
        payload = command[len(self.name) + 1:]
        payload = payload.replace("\\","\\\\");
        payload = payload.replace("'","\\'");
        if not payload:
            print "Usage: su password"
            return ""
        result = server.sendCommand("eggsu",payload,self.type,session.conn)
        if "root" in result:
            server.h.strinfo("Root Granted")
            time.sleep(0.2)
            server.h.strinfo("Escalating Privileges")
            server.refreshSession(session)
        else:
            print "failed getting root"
        return ""
