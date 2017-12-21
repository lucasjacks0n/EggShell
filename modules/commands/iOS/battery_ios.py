class command:
    def __init__(self):
        self.name = "battery"
        self.description = "get battery level"
    
    def run(self,session,cmd_data):
        print session.send_command(cmd_data)
