class command:
    def __init__(self):
        self.name = "getvol"
        self.description = "get volume level"
    
    def run(self,session,cmd_data):
        print session.send_command(cmd_data)
