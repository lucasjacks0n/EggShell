class command:
    def __init__(self):
        self.name = "pid"
        self.description = "get process id"
        self.type = "native"

    def run(self,session,cmd_data):
        print session.send_command(cmd_data)
