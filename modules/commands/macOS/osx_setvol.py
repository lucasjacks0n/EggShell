class payload:
    def __init__(self):
        self.name = "setvol"
        self.description = "set output volume"
        self.type = "applescript"
        self.id = 113
    
    def run(self,conn,server,command):
        if len(command.split()) < 2:
            print "Usage: setvol 0-100"
            return -1
        return "set volume output volume "+command.split()[1]+""
