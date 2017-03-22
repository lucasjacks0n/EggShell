class payload:
    def __init__(self):
        self.name = "sysinfo"
        self.description = "get system information"
        self.type = "native"
        self.id = 104

    def run(self,conn,server,command):
        return self.name
