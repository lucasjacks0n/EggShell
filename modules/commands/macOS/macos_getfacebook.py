class payload:
    def __init__(self):
        self.name = "getfacebook"
        self.description = "retrieve facebook session cookies"
        self.type = "native"
        self.id = 110

    def run(self,session,server,command):
        return self.name
