class payload:
    def __init__(self):
        self.name = "download"
        self.description = "download file"
        self.type = "download"
	self.id = 104

    def run(self,conn,server,command):
        return self.name
