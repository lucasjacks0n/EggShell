import modules
class payload:
    def __init__(self):
        self.name = "upload"
        self.description = "upload file"
        self.type = "upload"
        self.id = 105
    
    def run(self,session,server,command):
        args = command.split()
        if len(args) < 2:
            print "Usage: upload path/to/localfile"
        else:
            uploadTo = args[1].split("/")
            uploadTo = uploadTo[len(uploadTo) - 1]
            server.uploadFile(args[1],uploadTo,session.conn)
        return ""
