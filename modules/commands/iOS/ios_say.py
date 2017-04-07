class payload:
    def __init__(self):
        self.name = "say"
        self.description = "make device speak"
        self.type = "native"
        self.id = 124

    def run(self,session,server,command):
        return self.name
