class payload:
    def __init__(self):
        self.name = "openurl"
        self.description = "open url through the default browser"
        self.type = "native"
        self.id = 117

    def run(self,session,server,command):
        return self.name
