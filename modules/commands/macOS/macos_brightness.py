class payload:
    def __init__(self):
        self.name = "brightness"
        self.description = "adjust screen brightness"
        self.type = "native"
        self.id = 111
    
    def run(self,session,server,command):
        if len(command.split()) < 2:
            print "Usage: brightness 0.X"
            return ""
        return self.name
