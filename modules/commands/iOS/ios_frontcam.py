class payload:
    def __init__(self):
        self.name = "frontcam"
        self.description = "take picture through front camera"
        self.type = "download"
        self.id = 111

    def run(self,conn,server,command):
        return self.name
