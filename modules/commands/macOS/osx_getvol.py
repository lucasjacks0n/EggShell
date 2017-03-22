class payload:
    def __init__(self):
        self.name = "getvol"
        self.description = "get output volume"
        self.type = "applescript"
	self.id = 112

    def run(self,conn,server,command):
        return "output volume of (get volume settings)"
