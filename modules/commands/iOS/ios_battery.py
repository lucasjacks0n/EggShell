class payload:
    def __init__(self):
        self.name = "battery"
        self.description = "get battery level"
        self.type = "native"
        self.id = 107
    
    def run(self,session,server,command):
        return self.name
