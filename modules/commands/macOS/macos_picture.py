class payload:
    def __init__(self):
        self.name = "picture"
        self.description = "take picture through iSight"
        self.type = "download"
        self.id = 108

    def run(self,session,server,command):
        return self.name
