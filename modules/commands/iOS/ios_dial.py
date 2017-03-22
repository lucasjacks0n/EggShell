class payload:
    def __init__(self):
        self.name = "dial"
        self.description = "dial phone number"
        self.type = "native"
        self.id = 117

    def run(self,conn,server,command):
        return self.name
