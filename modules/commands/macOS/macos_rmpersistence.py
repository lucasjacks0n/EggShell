class payload:
    def __init__(self):
        self.name = "rmpersistence"
        self.description = "removes persistence"
        self.type = "native"
        self.id = 201

    def run(self,session,server,command):
        return self.name
