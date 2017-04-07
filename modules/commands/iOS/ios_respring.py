class payload:
    def __init__(self):
        self.name = "respring"
        self.description = "restart springboard"
        self.type = "native"
        self.id = 120

    def run(self,session,server,command):
        return self.name
