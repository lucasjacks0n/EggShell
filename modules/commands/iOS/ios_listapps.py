class payload:
    def __init__(self):
        self.name = "listapps"
        self.description = "list bundle identifiers"
        self.type = "native"
        self.id = 118

    def run(self,session,server,command):
        return self.name
