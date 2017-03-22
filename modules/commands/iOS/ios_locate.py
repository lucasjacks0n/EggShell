class payload:
    def __init__(self):
        self.name = "locate"
        self.description = "get device location coordinates"
        self.type = "native"
        self.id = 125

    def run(self,conn,server,command):
        return self.name
