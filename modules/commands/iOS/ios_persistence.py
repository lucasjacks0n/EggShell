class payload:
    def __init__(self):
        self.name = "persistence"
        self.description = "installs LaunchDaemon - tries to connect every 30 seconds"
        self.type = "native"
        self.id = 200

    def run(self,conn,server,command):
        return self.name
