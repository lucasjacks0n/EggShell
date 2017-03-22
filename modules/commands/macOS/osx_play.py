class payload:
    def __init__(self):
        self.name = "play"
        self.description = "tell iTunes to play"
        self.type = "applescript"
        self.id = 118

    def run(self,conn,server,command):
        return "tell application \"iTunes\" to play"
