class payload:
    def __init__(self):
        self.name = "next"
        self.description = "tell iTunes to play next track"
        self.type = "applescript"
        self.id = 121

    def run(self,conn,server,command):
        return "tell application \"iTunes\" to next track"
