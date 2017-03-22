class payload:
    def __init__(self):
        self.name = "brightness"
        self.description = "adjust screen brightness"
        self.type = "native"
        self.id = 111
    
    def run(self,conn,server,command):
        if len(command.split()) < 2:
            print "Usage: brightness 0.X"
            return -1
        return self.name
