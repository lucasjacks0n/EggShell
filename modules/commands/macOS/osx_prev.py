class payload:
    def __init__(self):
        self.name = "prev"
        self.description = "tell iTunes to play previous track"
        self.type = "applescript"
        self.id = 120
        
    def run(self,conn,server,command):
        return "tell application \"iTunes\" to previous track"
