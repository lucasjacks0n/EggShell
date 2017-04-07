class payload:
    def __init__(self):
        self.name = "openurl"
        self.description = "open url on device"
        self.type = "native"
        self.id = 116

    def run(self,session,server,command):
        return self.name
