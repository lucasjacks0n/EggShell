class payload:
    def __init__(self):
        self.name = "pid"
        self.description = "get proccess id"
        self.type = "native"
        self.id = 105

    def run(self,conn,server,command):
        return self.name
