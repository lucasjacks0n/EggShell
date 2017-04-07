class payload:
    def __init__(self):
        self.name = "download"
        self.description = "download file"
        self.type = "download"
        self.id = 113

    def run(self,session,server,command):
        return self.name
