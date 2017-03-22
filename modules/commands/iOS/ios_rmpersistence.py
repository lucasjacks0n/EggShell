class payload:
    def __init__(self):
        self.name = "rmpersistence"
        self.description = "uninstalls persistence"
        self.type = "native"
        self.id = 201

    def run(self,conn,server,command):
        return self.name
