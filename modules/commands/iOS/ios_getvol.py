class payload:
    def __init__(self):
        self.name = "getvol"
        self.description = "get media player volume"
        self.type = "native"
        self.id = 110

    def run(self,session,server,command):
        return self.name
