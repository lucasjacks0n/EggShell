class payload:
    def __init__(self):
        self.name = "idletime"
        self.description = "get the amount of time since the keyboard/cursor were touched"
        self.type = "native"
        self.id = 114

    def run(self,session,server,command):
        return self.name
