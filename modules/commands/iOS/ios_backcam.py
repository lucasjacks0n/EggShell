class payload:
    def __init__(self):
        self.name = "backcam"
        self.description = "take picture through back camera"
        self.type = "download"
        self.id = 112

    def run(self,session,server,command):
        return self.name
