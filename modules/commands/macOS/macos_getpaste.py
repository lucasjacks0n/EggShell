class payload:
    def __init__(self):
        self.name = "getpaste"
        self.description = "get pasteboard contents"
        self.type = "native"
        self.id = 106

    def run(self,session,server,command):
        return self.name
