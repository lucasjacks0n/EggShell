class payload:
    def __init__(self):
        self.name = "open"
        self.description = "open app"
        self.type = "native"
        self.id = 115

    def run(self,conn,server,command):
        return self.name
