class payload:
    def __init__(self):
        self.name = "pause"
        self.description = "tell iTunes to pause"
        self.type = "applescript"
        self.id = 119

    def run(self,conn,server,command):
        return "tell application \"iTunes\" to pause"
