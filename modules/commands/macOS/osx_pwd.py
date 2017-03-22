class payload:
    def __init__(self):
        self.name = "pwd"
        self.description = "get current directory"
        self.type = "native"
        self.id = 103

    def run(self,conn,server,command):
        return self.name
