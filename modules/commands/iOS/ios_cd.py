class payload:
    def __init__(self):
        self.name = "cd"
        self.description = "change directories"
        self.type = "native"
        self.id = 100

    def run(self,session,server,command):
        return self.name
