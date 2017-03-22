class payload:
    def __init__(self):
        self.name = "persistence"
        self.description = "attempts to connect back every 60 seconds"
        self.type = "native"
        self.id = 200

    def run(self,conn,server,command):
        return self.name
