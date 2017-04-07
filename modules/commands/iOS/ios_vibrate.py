class payload:
    def __init__(self):
        self.name = "vibrate"
        self.description = "make device vibrate"
        self.type = "native"
        self.id = 106

    def run(self,session,server,command):
        return self.name
