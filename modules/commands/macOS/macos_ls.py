class payload:
    def __init__(self):
        self.name = "ls"
        self.description = "list contents of directory"
        self.type = "native"
        self.id = 101

    def run(self,session,server,command):
        return self.name
