class payload:
    def __init__(self):
        self.name = "setvolume"
        self.description = "set media player volume"
        self.type = "native"
        self.id = 109
    
    def run(self,conn,server,command):
        return self.name
