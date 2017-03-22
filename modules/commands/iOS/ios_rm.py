class payload:
    def __init__(self):
        self.name = "rm"
        self.description = "delete file"
        self.type = "native"
        self.id = 102

    def run(self,conn,server,command):
        return self.name
